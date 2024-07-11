# frozen_string_literal: true

class FavoritesController < ApplicationController
  respond_to :html, :json
  skip_before_action :api_check

  def index
    if params[:tags]
      authorize(Favorite)
      redirect_to(posts_path(tags: params[:tags]))
    else
      user_id = params[:user_id] || CurrentUser.user.id
      @user = User.find(user_id)
      authorize(@user, policy_class: FavoritePolicy)

      raise(User::PrivacyModeError) if @user.hide_favorites?

      @favorite_set = PostSets::Favorites.new(@user, params[:page], limit: params[:limit])
      respond_with(@favorite_set.posts) do |fmt|
        fmt.json do
          render(json: @favorite_set.api_posts)
        end
      end
    end
  end

  def create
    @post = authorize(Post.find(params[:post_id]), policy_class: FavoritePolicy)
    FavoriteManager.add!(user: CurrentUser.user, post: @post)
    if params[:upvote].to_s.truthy?
      VoteManager::Posts.vote!(user: CurrentUser.user, post: @post, score: 1)
    end
    notice("You have favorited this post")

    respond_with(@post)
  rescue Favorite::Error, ActiveRecord::RecordInvalid => e
    render_expected_error(422, e.message)
  end

  def destroy
    @post = authorize(Post.find(params[:id]), policy_class: FavoritePolicy)
    FavoriteManager.remove!(user: CurrentUser.user, post: @post)

    notice("You have unfavorited this post")
    respond_with(@post)
  rescue Favorite::Error => e
    render_expected_error(422, e.message)
  end
end
