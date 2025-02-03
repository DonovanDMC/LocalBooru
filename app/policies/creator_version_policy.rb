# frozen_string_literal: true

class CreatorVersionPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[updater_ip_addr creator_name creator_id order]
  end
end
