# frozen_string_literal: true

class BulkUpdateRequestImporterPolicy < ApplicationPolicy
  def create?
    user.can_manage_aibur?
  end
end
