# frozen_string_literal: true

class User
  attr_reader :ip_addr

  def initialize(ip_addr, system: false, anonymous: false)
    ip = ip_addr.is_a?(IPAddr) ? ip_addr : IPAddr.new(ip_addr)
    if ip.ipv6?
      @ip_addr = ip.mask(64).to_s
    else
      @ip_addr = ip.to_s
    end
    @system = system
    @anonymous = anonymous
  end

  def name
    return "System" if @system
    return "Anonymous" if @anonymous
    "User[#{@ip_addr}]"
  end
  alias to_s name

  def self.system
    User.new("127.0.0.1", system: true)
  end

  def self.anonymous
    User.new("127.0.0.1", anonymous: true)
  end

  def is_system?
    @system
  end

  def is_anonymous?
    @anonymous
  end

  def is_banned?
    false
  end

  def is_member?
    !is_anonymous?
  end


  def init
    set_timezone
    set_statement_timeout
  end

  delegate :per_page, :statement_timeout, :default_image_size,
           :enable_keyboard_navigation?, :enable_autocomplete?, :style_usernames?,
           :move_related_thumbnails?, :top_notices?, :enable_hover_zoom?,
           :hover_zoom_shift?, :hover_zoom_sticky_shift?, :hover_zoom_play_audio?,
           to: :config

  private

  def config
    FemboyFans.config
  end

  def set_timezone
    Time.zone = FemboyFans.config.user_timezone
  end

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("set statement_timeout = #{statement_timeout}")
  end
end
