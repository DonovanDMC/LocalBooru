# frozen_string_literal: true

class MascotPolicy < ApplicationPolicy
  def create?
    user.is_admin?
  end

  def update?
    user.is_admin?
  end

  def destroy?
    user.is_admin?
  end

  def permitted_attributes
    %i[mascot_file display_name background_color creator_url creator_name available_on_string active hide_anonymous]
  end

  def api_attributes
    super + %i[url_path]
  end
end
