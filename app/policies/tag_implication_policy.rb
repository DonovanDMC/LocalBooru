# frozen_string_literal: true

class TagImplicationPolicy < ApplicationPolicy
  def permitted_attributes
    %i[antecedent_name consequent_name]
  end

  def permitted_attributes_for_create
    super + %i[reason]
  end

  def permitted_search_params
    super + %i[name_matches antecedent_name consequent_name status antecedent_tag_category consequent_tag_category creator_ip_addr approver_ip_addr rejector_ip_addr]
  end
end
