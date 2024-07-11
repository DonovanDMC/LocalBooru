# frozen_string_literal: true

require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  context "The favorites controller" do
    setup do
      @user = create(:user)
    end

    context "index action" do
      setup do
        @post = create(:post)
        FavoriteManager.add!(user: @user, post: @post)
      end

      context "with a specified tags parameter" do
        should "redirect to the posts controller" do
          get_auth favorites_path, @user, params: { tags: "fav:#{@user.name} abc" }
          assert_redirected_to(posts_path(tags: "fav:#{@user.name} abc"))
        end
      end

      should "display the current user's favorites" do
        get_auth favorites_path, @user
        assert_response :success
      end

      should "restrict access" do
        assert_access(User::Levels::MEMBER) { |user| get_auth favorites_path, user }
      end
    end

    context "create action" do
      setup do
        @post = create(:post)
      end

      should "create a favorite for the current user" do
        assert_difference({ "Favorite.count" => 1, "PostVote.count" => 0 }) do
          post_auth favorites_path, @user, params: { format: "json", post_id: @post.id }
        end
      end

      should "create a favorite and vote for the current user if upvote=true" do
        assert_difference(%w[Favorite.count PostVote.count], 1) do
          post_auth favorites_path, @user, params: { format: "json", post_id: @post.id, upvote: "true" }
        end
      end

      should "restrict access" do
        assert_access(User::Levels::MEMBER, success_response: :redirect) { |user| post_auth favorites_path, user, params: { post_id: @post.id } }
      end
    end

    context "destroy action" do
      setup do
        @post = create(:post)
        FavoriteManager.add!(user: @user, post: @post)
      end

      should "remove the favorite from the current user" do
        assert_difference("Favorite.count", -1) do
          delete_auth favorite_path(@post), @user, params: { format: "js" }
        end
      end

      should "restrict access" do
        assert_access(User::Levels::MEMBER, success_response: :redirect) { |user| delete_auth favorite_path(@post), user }
      end
    end
  end
end
