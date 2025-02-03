# frozen_string_literal: true

class TagImplication < TagRelationship
  has_many :tag_rel_undos, as: :tag_rel

  array_attribute :descendant_names

  before_save :update_descendant_names
  after_destroy :update_descendant_names_for_parents
  after_save :update_descendant_names_for_parents
  after_save :create_mod_action, if: :saved_change_to_status?
  with_options unless: :is_deleted? do
    validates :antecedent_name, uniqueness: { scope: [:consequent_name], conditions: -> { duplicate_relevant } }
    validate :absence_of_circular_relation
    validate :absence_of_transitive_relation
    validate :antecedent_is_not_aliased
    validate :consequent_is_not_aliased
  end

  module DescendantMethods
    extend ActiveSupport::Concern

    module ClassMethods
      # assumes names are normalized
      def with_descendants(names)
        (names + active.where(antecedent_name: names).flat_map(&:descendant_names)).uniq
      end

      def descendants_with_originals(names)
        active.where(antecedent_name: names).each_with_object({}) do |x, result|
          result[x.antecedent_name] ||= Set.new
          result[x.antecedent_name].merge(x.descendant_names)
        end
      end

      def cached_descendants(tag_name)
        Cache.fetch("descendants-#{tag_name}", expires_in: 1.day) do
          TagImplication.active.where("descendant_names && array[?]", tag_name).pluck(:antecedent_name)
        end
      end
    end

    def descendants
      @descendants ||= begin
        result = []
        children = [consequent_name]

        until children.empty?
          result.concat(children)
          children = TagImplication.active.where(antecedent_name: children).pluck(:consequent_name)
        end

        result.sort.uniq
      end
    end

    def invalidate_cached_descendants
      descendant_names.each do |tag_name|
        Cache.delete("descendants-#{tag_name}")
      end
    end

    def update_descendant_names
      self.descendant_names = descendants
    end

    def update_descendant_names!
      flush_cache
      update_descendant_names
      update_attribute(:descendant_names, descendant_names)
    end

    def update_descendant_names_for_parents
      parents.each do |parent|
        parent.update_descendant_names!
        parent.update_descendant_names_for_parents
      end
    end
  end

  module ParentMethods
    def parents
      @parents ||= self.class.duplicate_relevant.where(consequent_name: antecedent_name)
    end
  end

  module ValidationMethods
    def absence_of_circular_relation
      # We don't want a -> b && b -> a chains
      if descendants.include?(antecedent_name)
        errors.add(:base, "Tag implication can not create a circular relation with another tag implication")
      end
    end

    # If we already have a -> b -> c, don't allow a -> c.
    def absence_of_transitive_relation
      # Find everything else the antecedent implies, not including the current implication.
      implications = TagImplication.active.where("antecedent_name = ? and consequent_name != ?", antecedent_name, consequent_name)
      implied_tags = implications.flat_map(&:descendant_names)
      if implied_tags.include?(consequent_name)
        errors.add(:base, "#{antecedent_name} already implies #{consequent_name} through another implication")
      end
    end

    def antecedent_is_not_aliased
      # We don't want to implicate a -> b if a is already aliased to c
      if TagAlias.active.exists?(["antecedent_name = ?", antecedent_name])
        errors.add(:base, "Antecedent tag must not be aliased to another tag")
      end
    end

    def consequent_is_not_aliased
      # We don't want to implicate a -> b if b is already aliased to c
      if TagAlias.active.exists?(["antecedent_name = ?", consequent_name])
        errors.add(:base, "Consequent tag must not be aliased to another tag")
      end
    end
  end

  module ApprovalMethods
    def process!
      tries = 0

      begin
        CurrentUser.scoped(user: approver) do
          update!(status: "processing")
          CurrentUser.as_system { update_posts }
          update(status: "active")
          update_descendant_names_for_parents
        end
      rescue Exception => e
        if tries < 5 && !Rails.env.test?
          tries += 1
          sleep(2**tries)
          retry
        end

        update_columns(status: "error: #{e}")
      end
    end

    def approve!(approver = CurrentUser.user)
      update(status: "queued", approver_ip_addr: approver.ip_addr)
      invalidate_cached_descendants
      TagImplicationJob.perform_later(id)
    end

    def reject!(rejector = CurrentUser.user)
      update(status: "deleted", rejector_ip_addr: rejector.ip_addr)
      invalidate_cached_descendants
    end

    def create_mod_action
      implication = %("tag implication ##{id}":[#{Rails.application.routes.url_helpers.tag_implication_path(self)}]: [[#{antecedent_name}]] -> [[#{consequent_name}]])

      if previously_new_record?
        ModAction.log!(:tag_implication_create, self, implication_desc: implication)
      else
        # format the changes hash more nicely.
        change_desc = saved_changes.except(:updated_at).map do |attribute, values|
          old = values[0]
          new = values[1]
          if old.nil?
            %(set #{attribute} to "#{new}")
          else
            %(changed #{attribute} from "#{old}" to "#{new}")
          end
        end.join(", ")

        ModAction.log!(:tag_implication_update, self, implication_desc: implication, change_desc: change_desc)
      end
    end
  end

  include DescendantMethods
  include ParentMethods
  include ValidationMethods
  include ApprovalMethods

  def reload(options = {})
    flush_cache
    super
  end

  def flush_cache
    @dedescendants = nil
    @parents = nil
  end
end
