# frozen_string_literal: true

class ClearFavoritesJob < ApplicationJob
  queue_as :default

  def perform
    FavoriteManager.remove_all!
  end
end
