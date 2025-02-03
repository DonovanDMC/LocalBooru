# frozen_string_literal: true

source "https://rubygems.org/"

gem "dotenv", require: "dotenv/load"

gem "rails", "~> 7.1.0"
gem "pg"
gem "simple_form"
gem "ruby-vips"
gem "draper"
gem "streamio-ffmpeg"
gem "responders"
# gem "dtext_rb", git: "https://github.com/FemboyFans/dtext_rb.git", branch: "master", require: "dtext"
gem "dtext_rb", require: "dtext"
gem "bootsnap"
gem "addressable"
gem "webpacker", ">= 4.0.x"
gem "retriable"
gem "sidekiq", "~> 7.0"
gem "marcel"
# bookmarks for later, if they are needed
# gem 'sidekiq-worker-killer'
gem "sidekiq-unique-jobs"
gem "redis"
gem "request_store"

gem "diffy"
gem "rugged"

gem "opensearch-ruby"

gem "faraday"
gem "faraday-follow_redirects"
gem "faraday-retry"

group :production do
  gem "pitchfork"
end

group :development do
  gem "puma"
  gem "debug", require: false
  gem "rubocop", require: false
  gem "rubocop-erb", require: false
  gem "rubocop-rails", require: false
  gem "rexml", ">= 3.3.6"
  gem "ruby-lsp"
  gem "ruby-lsp-rails", "~> 0.3.13"
end

gem "pundit", "~> 2.3"
