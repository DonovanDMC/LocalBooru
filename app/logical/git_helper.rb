# frozen_string_literal: true

module GitHelper
  def self.init
    if Rails.root.join("REVISION").exist?
      @hash = Rails.root.join("REVISION").read.strip
    elsif system("type git > /dev/null && git rev-parse --show-toplevel > /dev/null")
      @hash = `git rev-parse HEAD`.strip
    else
      @hash = ""
    end
  end

  def self.hash
    @hash
  end

  def self.short_hash
    @hash[0..8]
  end

  def self.commit_url(commit_hash)
    "#{FemboyFans.config.source_code_url}/commit/#{commit_hash}"
  end

  def self.current_commit_url
    commit_url(@hash)
  end
end
