# frozen_string_literal: true

class ModActionPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[action subject_type subject_id creator_ip_addr]
  end

  def api_attributes
    super - %i[values] + record.json_keys
  end
end
