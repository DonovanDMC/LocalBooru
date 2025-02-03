# frozen_string_literal: true

class FavoritesController < ApplicationController
  respond_to :html, :json

  def index
    if params[:tags]
      redirect_to(posts_path(tags: params[:tags]))
    else
      @favorite_set = PostSets::Favorites.new(params[:page], limit: params[:limit])
      respond_with(@favorite_set.posts) do |fmt|
        fmt.json do
          render(json: @favorite_set.api_posts)
        end
      end
    end
  end

  def create
    @post = Post.find(params[:post_id])
    fav = FavoriteManager.add!(@post)
    notice("You have favorited this post")

    respond_with(fav)
  rescue Favorite::Error, ActiveRecord::RecordInvalid => e
    render_expected_error(422, e.message)
  end

  def destroy
    @post = Post.find(params[:id])
    FavoriteManager.remove!(@post)

    notice("You have unfavorited this post")
    respond_with(@post)
  rescue Favorite::Error => e
    render_expected_error(422, e.message)
  end

  def clear
    return if request.get? # will render the confirmation page
    FavoriteManager.clear_favorites
    respond_to do |format|
      format.html { redirect_to(favorites_path, notice: "Your favorites are being cleared. Give it some time if you have a lot") }
    end
  end
end
