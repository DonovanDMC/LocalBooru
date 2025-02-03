# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user || User.anonymous
    @record = record
  end

  def policy(object)
    Pundit.policy!(user, object)
  end

  def permitted_attributes
    []
  end

  def permitted_attributes_for_create
    permitted_attributes
  end

  def permitted_attributes_for_update
    permitted_attributes
  end

  def permitted_attributes_for_new
    permitted_attributes_for_create
  end

  def permitted_attributes_for_edit
    permitted_attributes_for_update
  end

  def visible_for_search(relation, _attribute = nil)
    relation
  end

  def permitted_search_params
    %i[id created_at updated_at order]
  end

  def api_attributes
    attr = record.class.column_names.map(&:to_sym)
    attr -= %i[uploader_ip_addr updater_ip_addr creator_ip_addr user_ip_addr ip_addr] unless can_see_ip_addr?
    attr
  end

  def html_data_attributes
    data_attributes = record.class.columns.select do |column|
      column.type.in?(%i[integer boolean datetime float uuid interval]) && !column.array?
    end.map(&:name).map(&:to_sym)

    api_attributes & data_attributes
  end

  def method_missing(method, *)
    return true if method.to_s.end_with?("?")
    super
  end
end
