#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

CurrentUser.scoped(ip_addr: "127.0.0.1") do
  count = rand(500..7000)
  Post.find(Post.pluck(:id).sample(count)).each do |post|
    FavoriteManager.add!(post)
  rescue Favorite::Error, ActiveRecord::RecordInvalid
    # ignore
  end
end
