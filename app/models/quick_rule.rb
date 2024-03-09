class QuickRule < ApplicationRecord
  validates :order, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  belongs_to :rule

  before_validation(on: :create) do
    self.order = (QuickRule.maximum(:order) || 0) + 1 if order.blank?
  end

  after_create :log_create
  after_update :log_update
  after_destroy :log_delete


  module LogMethods
    def log_create
      ModAction.log!(:quick_rule_create, self, reason: reason, header: header)
    end

    def log_update
      return unless saved_change_to_reason? || saved_change_to_header?
      ModAction.log!(:quick_rule_update, self,
                     reason: reason,
                     old_reason: reason_before_last_save,
                     header: header,
                     old_header: header_before_last_save)
    end

    def log_delete
      ModAction.log!(:quick_rule_delete, self, reason: reason, header: header)
    end
  end

  include LogMethods

  def self.log_reorder(total)
    ModAction.log!(:quick_rules_reorder, nil, total: total)
  end
end
