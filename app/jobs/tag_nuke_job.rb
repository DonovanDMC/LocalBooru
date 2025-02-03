# frozen_string_literal: true

class TagNukeJob < ApplicationJob
  queue_as :tags
  sidekiq_options lock: :until_executed, lock_args_method: :lock_args

  def self.lock_args(args)
    [args[0]]
  end

  def perform(*args)
    tag_name = args[0]
    tag = Tag.find_by_normalized_name(tag_name)
    updater = args[1]
    return if tag.nil?

    CurrentUser.scoped(user: updater) do
      CurrentUser.as_system { migrate_posts(tag.name) }
      ModAction.log!(:nuke_tag, Tag.find_by(name: tag_name), tag_name: tag_name)
    end
  end

  def migrate_posts(tag_name)
    Post.sql_raw_tag_match(tag_name).find_each do |post|
      post.with_lock do
        post.automated_edit = true
        post.remove_tag(tag_name)
        post.save
      end
    end
  end
end
