# frozen_string_literal: true

class RuleCategory < ApplicationRecord
  belongs_to_creator
  belongs_to_updater

  validates :order, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  has_many :rules, dependent: :destroy, foreign_key: :category_id

  before_validation(on: :create) do
    self.order = (RuleCategory.maximum(:order) || 0) + 1 if order.blank?
    self.anchor = name.parameterize if name && anchor.blank?
  end

  def format_rules(category)
    rules = category.rules.map do |rule|
      "#{category.order}.#{rule.order} [[##{rule.anchor}|#{rule.title}]]"
    end
    rules.join("\n")
  end

  after_create :log_create
  after_update :log_update
  after_destroy :log_delete

  module LogMethods
    def log_create
      ModAction.log!(:rule_category_create, self, name: name)
    end

    def log_update
      ModAction.log!(:rule_category_update, self, name: name, old_name: name_before_last_save)
    end

    def log_delete
      ModAction.log!(:rule_category_delete, self, name: name)
    end
  end

  include LogMethods

  def self.log_reorder(changes)
    ModAction.log!(:rule_categories_reorder, nil, total: changes)
  end
end
