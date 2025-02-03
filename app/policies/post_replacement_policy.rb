# frozen_string_literal: true

class PostReplacementPolicy < ApplicationPolicy
  def permitted_attributes
    %i[replacement_url replacement_file reason source as_pending]
  end

  def permitted_search_params
    super + %i[file_ext md5 status creator_ip_addr approver_ip_addr rejector_ip_addr uploader_ip_addr_on_approve]
  end

  def api_attributes
    super - %i[storage_id protected previous_details] + %i[file_url]
  end
end
