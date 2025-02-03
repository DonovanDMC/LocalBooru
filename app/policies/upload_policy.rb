# frozen_string_literal: true

class UploadPolicy < ApplicationPolicy
  def permitted_attributes
    %i[file direct_url source tag_string rating parent_id description]
  end

  def permitted_search_params
    super + %i[source source_matches rating parent_id post_id has_post post_tags_match status backtrace tag_string uploader_ip_addr]
  end
end
