# frozen_string_literal: true

class PostEventDecorator < ApplicationDecorator
  def self.collection_decorator_class
    PaginatedDecorator
  end

  delegate_all

  def format_description
    vals = object.extra_data

    case object.action
    when "deleted"
      (vals["reason"]).to_s
    when "favorites_moved"
      "Target: post ##{vals['parent_id']}"
    when "favorites_received"
      "From: post ##{vals['child_id']}"
    when "replacement_promoted"
      "From: post ##{vals['source_post_id']}"
    when "changed_bg_color"
      "To: #{vals['bg_color'] || 'None'}"
    when "changed_thumbnail_frame"
      "#{vals['old_thumbnail_frame'] || 'Default'} -> #{vals['new_thumbnail_frame'] || 'Default'}"
    when "replacement_accepted", "replacement_rejected"
      "\"replacement ##{vals['post_replacement_id']}\":/posts/replacements?search[id]=#{vals['post_replacement_id']}"
    end
  end
end
