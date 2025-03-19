# frozen_string_literal: true

class CreatorUrlPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[creator_name url_matches normalized_url_matches is_active order]
  end
end
