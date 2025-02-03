# frozen_string_literal: true

class StaticController < ApplicationController
  respond_to :text, only: %i[robots]

  def not_found
    render("static/404", formats: [:html], status: 404)
  end

  def error
  end

  def home
    redirect_to(posts_path)
    # render(layout: "blank")
  end

  def theme
  end

  def toggle_mobile_mode
    if cookies[:nmm]
      cookies.delete(:nmm)
    else
      cookies.permanent[:nmm] = "1"
    end
    redirect_back(fallback_location: posts_path)
  end

  def robots
    expires_in(1.day, public: true)
  end
end
