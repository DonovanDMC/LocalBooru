# frozen_string_literal: true

module Admin
  class DestroyedPostsController < ApplicationController
    respond_to :html

    def index
      @destroyed_posts = DestroyedPost.search(search_params(DestroyedPost)).paginate(params[:page], limit: params[:limit])
    end

    def show
      redirect_to(admin_destroyed_posts_path(search: { post_id: params[:id] }))
    end
  end
end
