class UserSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.is_a?(User)
  end

  def serialize(user)
    super("ip_addr" => user.ip_addr, "system" => user.is_system?, "anonymous" => user.is_anonymous?)
  end

  def deserialize(hash)
    User.new(hash["ip_addr"], system: hash["system"], anonymous: hash["anonymous"])
  end

  private

  def klass
    User
  end
end
