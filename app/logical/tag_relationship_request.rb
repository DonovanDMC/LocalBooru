# frozen_string_literal: true

class TagRelationshipRequest
  include ActiveModel::Validations

  attr_reader :antecedent_name, :consequent_name, :tag_relationship, :reason

  validate :validate_tag_relationship

  def initialize(antecedent_name:, consequent_name:, reason: "")
    @antecedent_name = antecedent_name&.strip&.tr(" ", "_")
    @consequent_name = consequent_name&.strip&.tr(" ", "_")
    @reason = reason
  end

  def self.create(...)
    new(...).create
  end

  def create
    return self if invalid?

    tag_relationship_class.transaction do
      @tag_relationship = build_tag_relationship
      @tag_relationship.save
    end

    self
  end

  def build_tag_relationship
    x = tag_relationship_class.new(
      antecedent_name: antecedent_name,
      consequent_name: consequent_name,
      reason:          reason,
    )
    x.status = "pending"
    x
  end

  def validate_tag_relationship
    tag_relationship = @tag_relationship || build_tag_relationship

    if tag_relationship.invalid?
      errors.merge!(tag_relationship.errors)
    end
  end
end
