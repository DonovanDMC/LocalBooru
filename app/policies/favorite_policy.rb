# frozen_string_literal: true

class FavoritePolicy < ApplicationPolicy
  def api_attributes
    super + %i[post]
  end
end
