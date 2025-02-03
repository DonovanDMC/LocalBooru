# frozen_string_literal: true

class TagAlias < TagRelationship
  after_save :create_mod_action
  validates :antecedent_name, uniqueness: { conditions: -> { duplicate_relevant } }, unless: :is_deleted?
  validate :absence_of_transitive_relation, unless: :is_deleted?

  module ApprovalMethods
    def approve!(approver = CurrentUser.user)
      CurrentUser.scoped(user: approver) do
        update(status: "queued", approver_ip_addr: approver.ip_addr)
        TagAliasJob.perform_later(id)
      end
    end
  end

  module TransitiveChecks
    def list_transitives
      return @transitives if @transitives
      @transitives = []
      aliases = TagAlias.duplicate_relevant.where("consequent_name = ?", antecedent_name)
      aliases.each do |ta|
        @transitives << [:alias, ta, ta.antecedent_name, ta.consequent_name, consequent_name]
      end

      implications = TagImplication.duplicate_relevant.where("antecedent_name = ? or consequent_name = ?", antecedent_name, antecedent_name)
      implications.each do |ti|
        if ti.antecedent_name == antecedent_name
          @transitives << [:implication, ti, ti.antecedent_name, ti.consequent_name, consequent_name, ti.consequent_name]
        else
          @transitives << [:implication, ti, ti.antecedent_name, ti.consequent_name, ti.antecedent_name, consequent_name]
        end
      end

      @transitives
    end

    def has_transitives
      @has_transitives ||= !list_transitives.empty?
    end
  end

  include ApprovalMethods
  include TransitiveChecks

  def self.to_aliased_with_originals(names)
    names = Array(names).map(&:to_s)
    return {} if names.empty?
    aliases = active.where(antecedent_name: names).to_h { |ta| [ta.antecedent_name, ta.consequent_name] }
    names.to_h { |tag| [tag, tag] }.merge(aliases)
  end

  def self.to_aliased(names)
    TagAlias.to_aliased_with_originals(names).values
  end

  def self.to_aliased_query(query, overrides: nil, comments: false)
    # Remove tag types (newline syntax)
    query.gsub!(/(^| )(-)?(#{TagCategory.mapping.keys.sort_by { |x| -x.size }.join('|')}):([\S])/i, '\1\2\4')
    # Remove tag types (comma syntax)
    query.gsub!(/, (-)?(#{TagCategory.mapping.keys.sort_by { |x| -x.size }.join('|')}):([\S])/i, ', \1\3')
    lines = query.downcase.split("\n")
    processed = []
    lookup = []

    lines.each do |line|
      content = { tags: [] }
      if line.strip.empty?
        processed << content
        next
      end

      # Remove comments
      comment = line.match(/(?: |^)#(.*)/)
      unless comment.nil?
        content[:comment] = comment[1].strip
        line = line.delete_suffix("##{comment[1]}")
      end

      # Process tags
      line.split.compact_blank.map do |tag|
        data = {
          opt: tag.match(/^-?~/),
          neg: tag.match(/^~?-/),
          tag: tag.gsub(/^[-~]{1,}/, ""),
        }

        # ex. only - or ~ surrounded by spaces
        next if data[:tag].empty?

        content[:tags] << data
        lookup << data[:tag]
      end

      processed << content
    end

    # Look up the aliases
    aliases = to_aliased_with_originals(lookup.uniq)
    aliases.merge!(overrides) if overrides

    # Rebuild the blacklist text
    output = processed.map do |line|
      output_line = line[:tags].map do |data|
        (data[:opt] ? "~" : "") + (data[:neg] ? "-" : "") + (aliases[data[:tag]] || data[:tag])
      end
      output_line << "# #{line[:comment]}" if comments && !line[:comment].nil?

      output_line.uniq.join(" ")
    end

    # TODO: This causes every empty line except for the very first one will get stripped.
    # At the end of the day, it's not a huge deal.
    output.uniq.join("\n")
  end

  def process!
    tries = 0

    begin
      CurrentUser.scoped(user: approver) do
        update!(status: "processing")
        move_aliases_and_implications
        ensure_category_consistency
        CurrentUser.as_system { update_posts }
        update(status: "active", post_count: consequent_tag.post_count)
        # TODO: Race condition with indexing jobs here.
        antecedent_tag.fix_post_count if antecedent_tag&.persisted?
        consequent_tag.fix_post_count if consequent_tag&.persisted?
      end
    rescue Exception => e
      Rails.logger.error("[TA] #{e.message}\n#{e.backtrace}")
      if tries < 5 && !Rails.env.test?
        tries += 1
        sleep(2**tries)
        retry
      end

      CurrentUser.scoped(user: approver) do
        update_columns(status: "error: #{e}")
      end
    end
  end

  def absence_of_transitive_relation
    # We don't want a -> b && b -> c chains if the b -> c alias was created first.
    # If the a -> b alias was created first, the new one will be allowed and the old one will be moved automatically instead.
    if TagAlias.active.exists?(antecedent_name: consequent_name)
      errors.add(:base, "A tag alias for #{consequent_name} already exists")
    end
  end

  def move_aliases_and_implications
    aliases = TagAlias.where(["consequent_name = ?", antecedent_name])
    aliases.each do |ta|
      ta.consequent_name = consequent_name
      success = ta.save
      if !success && ta.errors.full_messages.join("; ") =~ /Cannot alias a tag to itself/
        ta.destroy
      end
    end

    implications = TagImplication.where(["antecedent_name = ?", antecedent_name])
    implications.each do |ti|
      ti.antecedent_name = consequent_name
      success = ti.save
      if !success && ti.errors.full_messages.join("; ") =~ /Cannot implicate a tag to itself/
        ti.destroy
      end
    end

    implications = TagImplication.where(["consequent_name = ?", antecedent_name])
    implications.each do |ti|
      ti.consequent_name = consequent_name
      success = ti.save
      if !success && ti.errors.full_messages.join("; ") =~ /Cannot implicate a tag to itself/
        ti.destroy
      end
    end
  end

  def ensure_category_consistency
    return if consequent_tag.post_count > FemboyFans.config.alias_category_change_cutoff # Don't change category of large established tags.
    return unless consequent_tag.general? # Don't change the already existing category of the target tag
    return if antecedent_tag.general? # Don't set the target tag to general

    consequent_tag.update(category: antecedent_tag.category, reason: "alias ##{id} (#{antecedent_tag.name} -> #{consequent_tag.name})")
  end

  def rename_creator
    if antecedent_tag.creator? && (antecedent_tag.creator.present? && consequent_tag.creator.blank?)
      antecedent_tag.creator.update!(name: consequent_name)
    end
  end

  def reject!(rejector = CurrentUser.user)
    update(status: "deleted", rejector_ip_addr: rejector.ip_addr)
  end

  def self.update_cached_post_counts_for_all
    TagAlias.without_timeout do
      connection.execute("UPDATE tag_aliases SET post_count = tags.post_count FROM tags WHERE tags.name = tag_aliases.consequent_name")
    end
  end

  def create_mod_action
    alias_desc = %("tag alias ##{id}":[#{Rails.application.routes.url_helpers.tag_alias_path(self)}]: [[#{antecedent_name}]] -> [[#{consequent_name}]])

    if previously_new_record?
      ModAction.log!(:tag_alias_create, self, alias_desc: alias_desc)
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

      ModAction.log!(:tag_alias_update, self, alias_desc: alias_desc, change_desc: change_desc)
    end
  end

  def self.fix_nonzero_post_counts!
    TagAlias.joins(:antecedent_tag).where("tag_aliases.status in ('active', 'processing') AND tags.post_count != 0").find_each { |ta| ta.antecedent_tag.fix_post_count }
  end
end
