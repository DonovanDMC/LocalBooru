# frozen_string_literal: true

class TagAliasRequest < TagRelationshipRequest
  def tag_relationship_class
    TagAlias
  end
end
