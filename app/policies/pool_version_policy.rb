# frozen_string_literal: true

class PoolVersionPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[updater_ip_addr pool_id is_active]
  end
end
