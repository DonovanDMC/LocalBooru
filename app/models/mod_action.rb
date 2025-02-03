# frozen_string_literal: true

class ModAction < ApplicationRecord
  belongs_to_creator
  belongs_to_user :user
  belongs_to :subject, polymorphic: true, optional: true
  cattr_accessor :disable_logging, default: false

  # inline results in rubocop aligning everything with :values
  VALUES = %i[
    pool_name
    user_ip_addr
    tag_name antecedent consequent alias_desc implication_desc change_desc
  ].freeze

  store_accessor :values, *VALUES

  def self.log(...)
    Rails.logger.warn("ModAction: use ModAction.log! instead of ModAction.log")
    log!(...)
  end

  def self.log!(action, subject, **details)
    if disable_logging
      Rails.logger.warn("ModAction: skipped logging for #{action} #{subject&.class&.name} #{details.inspect}")
      return
    end
    create!(action: action.to_s, subject: subject, values: details)
  end

  FORMATTERS = {
    ### Bulk Update Request ###
    mass_update:            {
      text: ->(mod, _user) { "Mass updated [[#{mod.antecedent}]] -> [[#{mod.consequent}]]" },
      json: %i[antecedent consequent],
    },
    nuke_tag:               {
      text: ->(mod, _user) { "Nuked tag [[#{mod.tag_name}]]" },
      json: %i[tag_name],
    },

    ### Pools ###
    pool_delete:            {
      text: ->(mod, user) { "Deleted pool ##{mod.subject_id} (named #{mod.pool_name}) by #{user}" },
      json: %i[pool_name user_ip_addr],
    },

    ### Alias ###
    tag_alias_create:       {
      text: ->(mod, _user) { "Created #{mod.alias_desc}" },
      json: %i[alias_desc],
    },
    tag_alias_update:       {
      text: ->(mod, _user) { "Updated #{mod.alias_desc}\n#{mod.change_desc}" },
      json: %i[alias_desc change_desc],
    },

    ### Implication ###
    tag_implication_create: {
      text: ->(mod, _user) { "Created #{mod.implication_desc}" },
      json: %i[implication_desc],
    },
    tag_implication_update: {
      text: ->(mod, _user) { "Updated #{mod.implication_desc}\n#{mod.change_desc}" },
      json: %i[implication_desc change_desc],
    },
  }.freeze

  def format_unknown(mod, _user)
    "Unknown action #{mod.action}: #{mod.values.inspect}"
  end

  def self.url
    Rails.application.routes.url_helpers
  end

  def format_text
    FORMATTERS[action.to_sym]&.[](:text)&.call(self, user) || format_unknown(self, user)
  end

  def json_keys
    formatter = FORMATTERS[action.to_sym]&.[](:json)
    return values.keys unless formatter
    formatter.is_a?(Proc) ? formatter.call(self, user) : formatter
  end

  def format_json
    keys = FORMATTERS[action.to_sym]&.[](:json)
    return values if keys.nil?
    keys = keys.call(self, user) if keys.is_a?(Proc)
    keys.index_with { |k| send(k) }
  end

  KNOWN_ACTIONS = FORMATTERS.keys.freeze

  module SearchMethods
    def search(params)
      q = super

      q = q.where_user(:creator_ip_addr, :creator_ip_addr, params)
      q = q.where_user(:user_ip_addr, :user_ip_addr, params)
      q = q.where(action: params[:action].split(",")) if params[:action].present?
      q = q.attribute_matches(:subject_type, params[:subject_type])
      q = q.attribute_matches(:subject_id, params[:subject_id])

      q.apply_basic_order(params)
    end
  end

  extend SearchMethods

  def self.without_logging(&)
    self.disable_logging = true
    yield
  ensure
    self.disable_logging = false
  end

  def serializable_hash(*)
    return super.merge("#{subject_type.underscore}_id": subject_id) if subject
    super
  end
end
