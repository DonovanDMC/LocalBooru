# frozen_string_literal: true

class PostPolicy < ApplicationPolicy
  def permitted_attributes_for_update
    %i[
      tag_string old_tag_string
      tag_string_diff source_diff
      source old_source
      parent_id old_parent_id
      description old_description
      rating old_rating
      edit_reason thumbnail_frame
      bg_color
      hide_from_search_engines
    ]
  end

  # due to how internals work (inline editing), this is needed
  def permitted_attributes_for_show
    permitted_attributes_for_update
  end

  def permitted_attributes_for_mark_as_translated
    %i[]
  end

  def api_attributes
    attr = super + %i[has_large has_visible_children children_ids pool_ids is_favorited?] - %i[pool_string]
    attr += %i[file_url large_file_url preview_file_url] if record.visible?
    attr -= %i[md5 file_ext] unless record.visible?
    attr
  end
end
