# frozen_string_literal: true

class TagImplicationRequest < TagRelationshipRequest
  def tag_relationship_class
    TagImplication
  end
end
