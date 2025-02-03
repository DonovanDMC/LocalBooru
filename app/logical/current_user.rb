# frozen_string_literal: true

class CurrentUser
  def self.scoped(user: nil, ip_addr: "127.0.0.1")
    old_user = self.user
    old_ip_addr = self.ip_addr

    self.user = user || User.new(ip_addr)
    self.ip_addr = user.try(:ip_addr) || ip_addr

    begin
      yield
    ensure
      self.user = old_user
      self.ip_addr = old_ip_addr
    end
  end

  def self.as_system(&)
    scoped(user: User.system, &)
  end

  def self.user=(user)
    RequestStore[:current_user] = user
  end

  def self.ip_addr=(ip_addr)
    RequestStore[:current_ip_addr] = ip_addr
  end

  def self.user
    RequestStore[:current_user]
  end

  def self.ip_addr
    RequestStore[:current_ip_addr]
  end

  def self.name
    user.name
  end

  def self.method_missing(...)
    user.__send__(...)
  end
end
