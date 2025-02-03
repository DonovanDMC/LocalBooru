# frozen_string_literal: true

class DestroyedPostPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[destroyer_ip_addr uploader_ip_addr post_id md5 reason_matches]
  end
end
