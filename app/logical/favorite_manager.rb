# frozen_string_literal: true

class FavoriteManager
  ISOLATION = Rails.env.test? ? {} : { isolation: :repeatable_read }

  def self.add!(post, force: false)
    retries = 5
    begin
      Favorite.transaction(**ISOLATION) do
        Favorite.create(post_id: post.id)
      end
    rescue ActiveRecord::SerializationFailure => e
      retries -= 1
      retry if retries > 0
      raise(e)
    rescue ActiveRecord::RecordNotUnique
      raise(Favorite::Error, "You have already favorited this post") unless force
    end
  end

  def self.remove!(post)
    retries = 5
    begin
      return unless Favorite.exists?(post_id: post.id)
      Favorite.transaction(**ISOLATION) do
        Favorite.where(post_id: post.id).destroy_all
      end
    rescue ActiveRecord::SerializationFailure => e
      retries -= 1
      retry if retries > 0
      raise(e)
    end
  end

  def self.clear_favorites
    ClearFavoritesJob.perform_later
  end

  def self.remove_all!
    Favorite.delete_all
    Post.document_store.import # Easier to re-import everything since we likely don't have enough posts for it to matter
  end

  def self.give_to_parent!(post)
    # TODO: Much better and more intelligent logic can exist for this
    parent = post.parent
    return false unless parent
    FavoriteManager.remove!(post)
    FavoriteManager.add!(parent, force: true)
    true
  end
end
