# frozen_string_literal: true

module Posts
  class MoveFavoritesController < ApplicationController
    respond_to :html, :json

    def show
      @post = Post.find(params[:id])
      respond_with(@post)
    end

    def create
      @post = Post.find(params[:id])
      @post.give_favorites_to_parent
      respond_with(@post)
    end
  end
end
