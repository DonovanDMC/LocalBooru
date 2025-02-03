# frozen_string_literal: true

class PoolPolicy < ApplicationPolicy
  def permitted_attributes
    [:name, :description, :is_active, :post_ids_string, { post_ids: [] }]
  end

  def permitted_search_params
    super + %i[name_matches description_matches any_creator_name_like any_creator_name_matches category is_active creator_ip_addr]
  end

  def api_attributes
    super + %i[creator_names post_count]
  end
end
