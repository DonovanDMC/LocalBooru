# frozen_string_literal: true

class TagBatchJob < ApplicationJob
  queue_as :tags

  def perform(*args)
    antecedent = args[0]
    consequent = args[1]
    updater = args[2]

    from, *from_remaining = TagQuery.scan(antecedent.downcase)
    to, *to_remaining = TagQuery.scan(consequent.downcase)
    raise(JobError, "#{antecedent} or #{consequent} has unexpected format") if from_remaining.any? || to_remaining.any?

    CurrentUser.scoped(user: updater) do
      CurrentUser.as_system { migrate_posts(from, to) }
      ModAction.log!(:mass_update, nil, antecedent: antecedent, consequent: consequent)
    end
  end

  def migrate_posts(from, to)
    Post.sql_raw_tag_match(from).find_each do |post|
      post.with_lock do
        post.automated_edit = true
        post.remove_tag(from)
        post.add_tag(to)
        post.save
      end
    end
  end
end
