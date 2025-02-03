# frozen_string_literal: true

require "dtext/dtext"
require "dtext/version"

begin
  require "zeitwerk"

  loader = Zeitwerk::Loader.for_gem
  loader.enable_reloading
  loader.inflector.inflect("dtext" => "DText")
  #loader.logger = Logger.new(STDERR)
  loader.setup
rescue LoadError
end

class DText
  class Error < StandardError; end

  def self.parse(str, inline: false, allow_color: false, qtags: false, base_url: nil, domain: nil, internal_domains: [])
    c_parse(str, base_url, domain, internal_domains, inline, allow_color, qtags)
  end
end
