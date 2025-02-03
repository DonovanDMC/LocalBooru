# frozen_string_literal: true

class Favorite < ApplicationRecord
  class Error < StandardError; end
  belongs_to_creator

  belongs_to :post
  scope :for_posts, ->(post_ids) { where(post_id: post_ids) }
  after_commit -> { post.update_index }

  def self.available_includes
    %i[post]
  end
end
