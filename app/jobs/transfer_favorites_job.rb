# frozen_string_literal: true

class TransferFavoritesJob < ApplicationJob
  queue_as :low_prio

  def perform(*args)
    @post = Post.find_by(id: args[0])
    @user = args[1]
    unless @post && @user
      # Something went wrong and there is nothing we can do inside the job.
      return
    end

    CurrentUser.scoped(user: @user) do
      @post.give_favorites_to_parent!
    end
  end
end
