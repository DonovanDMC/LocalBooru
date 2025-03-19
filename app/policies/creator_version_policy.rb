# frozen_string_literal: true

class CreatorVersionPolicy < ApplicationPolicy
  def permitted_search_params
    params = super + %i[updater_name updater_id creator_name creator_id order]
    params += %i[ip_addr] if can_search_ip_addr?
    params
  end
end
