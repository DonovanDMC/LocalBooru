# frozen_string_literal: true

class PostEvent < ApplicationRecord
  belongs_to_creator
  belongs_to :post
  enum :action, {
    deleted:                 0,
    undeleted:               1,
    favorites_moved:         6,
    favorites_received:      7,
    replacement_accepted:    14,
    replacement_rejected:    15,
    replacement_promoted:    20,
    replacement_deleted:     16,
    expunged:                17,
    changed_bg_color:        23,
    changed_thumbnail_frame: 24,
  }

  def self.add(...)
    Rails.logger.warn("PostEvent: use PostEvent.add! instead of PostEvent.add")
    add!(...)
  end

  def self.add!(post_id, user, action, data = {})
    create!(post_id: post_id, creator_ip_addr: user.ip_addr, action: action.to_s, extra_data: data)
  end

  module SearchMethods
    def search(params)
      q = super

      q = q.where_user(:creator_ip_addr, :creator_ip_addr, params)
      if params[:post_id].present?
        q = q.where(post_id: params[:post_id])
      end

      if params[:action].present?
        q = q.where(action: actions[params[:action]])
      end

      q.apply_basic_order(params)
    end
  end

  module ApiMethods
    # whitelisted data attributes
    def allowed_data
      %w[reason parent_id child_id bg_color post_replacement_id old_md5 new_md5 source_post_id md5]
    end

    def serializable_hash(*)
      super.merge(**extra_data.slice(*allowed_data))
    end
  end

  include ApiMethods
  extend SearchMethods

  def self.available_includes
    %i[post]
  end
end
