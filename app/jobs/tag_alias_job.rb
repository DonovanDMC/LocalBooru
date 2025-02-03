# frozen_string_literal: true

class TagAliasJob < ApplicationJob
  queue_as :tags
  sidekiq_options lock: :until_executed, lock_args_method: :lock_args

  def self.lock_args(args)
    [args[0]]
  end

  def perform(id)
    ta = TagAlias.find(id)
    ta.process!
  end
end
