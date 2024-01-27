source 'https://rubygems.org/'

gem 'dotenv-rails', require: 'dotenv/rails-now'

gem "rails", "~> 7.1.0"
gem "pg"
gem "dalli", :platforms => :ruby
gem "simple_form"
gem 'active_model_serializers', '~> 0.10.0'
gem 'ruby-vips'
gem 'bcrypt', :require => "bcrypt"
gem 'draper'
gem 'streamio-ffmpeg'
gem 'responders'
gem "dtext_rb", git: "https://github.com/PawsMovin/dtext_rb.git", branch: "master", require: "dtext"
gem 'bootsnap'
gem 'addressable'
gem 'httparty'
gem 'recaptcha', require: "recaptcha/rails"
gem 'webpacker', '>= 4.0.x'
gem 'retriable'
gem 'sidekiq', '~> 7.0'
gem 'marcel'
# bookmarks for later, if they are needed
# gem 'sidekiq-worker-killer'
gem 'sidekiq-unique-jobs'
gem 'redis'
gem 'request_store'
gem 'newrelic_rpm'

gem "diffy"
gem "rugged"

# Blocked by unicorn which lacks a release with Rack 3 support
gem "rack", "~> 2.0"

gem 'opensearch-ruby'

gem 'mailgun-ruby'

group :production do
  gem 'unicorn'
  gem 'unicorn-worker-killer'
end

group :development, :test do
  gem 'listen'
  gem 'puma'
end

group :development do
  gem "debug", require: false
  gem "rubocop", require: false
  gem "rubocop-erb", require: false
  gem "rubocop-rails", require: false
  gem "ruby-lsp"
  gem "ruby-lsp-rails"
end

group :test do
  gem "shoulda-context", require: false
  gem "shoulda-matchers", require: false
  gem "factory_bot_rails", require: false
  gem "mocha", require: false
  gem "webmock", require: false
end
