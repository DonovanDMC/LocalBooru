# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def permitted_attributes
    %i[category reason]
  end

  def permitted_search_params
    super + %i[fuzzy_name_matches name_matches name category hide_empty]
  end
end
