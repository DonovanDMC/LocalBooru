# frozen_string_literal: true

require "test_helper"

class ForumPostsControllerTest < ActionDispatch::IntegrationTest
  context "The forum posts controller" do
    setup do
      @user = create(:user)
      @other_user = create(:user)
      @mod = create(:moderator_user)
      as(@user) do
        @forum_topic = create(:forum_topic, title: "my forum topic", original_post_attributes: { body: "alias xxx -> yyy" })
        @forum_post = @forum_topic.original_post
      end
    end

    context "with votes" do
      setup do
        as(@user) do
          @tag_alias = create(:tag_alias, forum_post: @forum_post, status: "pending")
          @forum_post.update_columns(tag_change_request_id: @tag_alias.id, tag_change_request_type: "TagAlias")
          @vote = create(:forum_post_vote, forum_post: @forum_post, score: 1)
          @forum_post.reload
        end
      end

      should "not render the vote links for the requesting user" do
        get_auth forum_topic_path(@forum_topic), @user
        assert_select "a[title='Vote up']", false
      end

      should "render the vote links" do
        get_auth forum_topic_path(@forum_topic), @mod
        assert_select "a[title='Vote up']"
      end

      should "render existing votes" do
        get_auth forum_topic_path(@forum_topic), @mod
        assert_select "li.vote-score-up"
      end

      context "after the alias is rejected" do
        setup do
          as(@mod) do
            @tag_alias.reject!
          end
          get_auth forum_topic_path(@forum_topic), @mod
        end

        should "hide the vote links" do
          assert_select "a[title='Vote up']", false
        end

        should "still render existing votes" do
          assert_select "li.vote-score-up"
        end
      end
    end

    context "index action" do
      should "list all forum posts" do
        get forum_posts_path
        assert_response :success
      end

      context "with search conditions" do
        should "list all matching forum posts" do
          get forum_posts_path, params: { search: { body_matches: "xxx" } }
          assert_response :success
          assert_select "#forum-post-#{@forum_post.id}"
        end

        should "list nothing for when the search matches nothing" do
          get forum_posts_path, params: { search: { body_matches: "bababa" } }
          assert_response :success
          assert_select "#forum-post-#{@forum_post.id}", false
        end

        should "list by creator id" do
          get forum_posts_path, params: { search: { creator_id: @user.id } }
          assert_response :success
          assert_select "#forum-post-#{@forum_post.id}"
        end
      end
    end

    context "edit action" do
      should "render if the editor is the creator of the topic" do
        get_auth edit_forum_post_path(@forum_post), @user
        assert_response :success
      end

      should "render if the editor is an admin" do
        get_auth edit_forum_post_path(@forum_post), create(:admin_user)
        assert_response :success
      end

      should "fail if the editor is not the creator of the topic and is not an admin" do
        get_auth edit_forum_post_path(@forum_post), @other_user
        assert_response(403)
      end
    end

    context "new action" do
      should "render" do
        get_auth new_forum_post_path, @user, params: { forum_post: { topic_id: @forum_topic.id } }
        assert_response :success
      end
    end

    context "create action" do
      should "create a new forum post" do
        assert_difference("ForumPost.count", 1) do
          post_auth forum_posts_path, @user, params: { forum_post: { body: "xaxaxa", topic_id: @forum_topic.id } }
          assert_redirected_to(forum_topic_path(ForumPost.last.topic, page: ForumPost.last.forum_topic_page, anchor: "forum_post_#{ForumPost.last.id}"))
        end
      end

      should "not create a new forum post if topic is stale" do
        travel_to(1.year.from_now) do
          assert_no_difference("ForumPost.count") do
            post_auth forum_posts_path, @user, params: { forum_post: { body: "xaxaxa", topic_id: @forum_topic.id }, format: :json }
            assert_response :unprocessable_entity
            assert_includes(@response.parsed_body.dig("errors", "topic"), "is stale. New posts cannot be created")
          end
        end
      end

      should "still create a new forum post if topic is stale for moderators" do
        travel_to(1.year.from_now) do
          assert_difference("ForumPost.count", 1) do
            post_auth forum_posts_path, @mod, params: { forum_post: { body: "xaxaxa", topic_id: @forum_topic.id }, format: :json }
            assert_response :success
          end
        end
      end
    end

    context "destroy action" do
      should "destroy the posts" do
        @admin = create(:admin_user)
        delete_auth forum_post_path(@forum_post), @admin
        get_auth forum_post_path(@forum_post), @admin
        assert_response :not_found
      end
    end

    context "unhide action" do
      setup do
        as(@mod) do
          @forum_post.hide!
        end
      end

      should "restore the post" do
        put_auth unhide_forum_post_path(@forum_post), @mod
        assert_redirected_to(forum_post_path(@forum_post))
        @forum_post.reload
        assert_equal(false, @forum_post.is_hidden?)
      end
    end

    context "spam" do
      setup do
        SpamDetector.stubs(:enabled?).returns(true)
        stub_request(:post, %r{https://.*\.rest\.akismet\.com/(\d\.?)+/comment-check}).to_return(status: 200, body: "true")
        stub_request(:post, %r{https://.*\.rest\.akismet\.com/(\d\.?)+/submit-spam}).to_return(status: 200, body: nil)
      end

      should "mark spam forum posts as spam" do
        SpamDetector.any_instance.stubs(:spam?).returns(true)
        assert_difference("User.system.tickets.count", 1) do
          assert_difference("ForumPost.count", 1) do
            post_auth forum_posts_path, @user, params: { forum_post: { body: "abc", topic_id: @forum_topic.id } }
            @ticket = User.system.tickets.last
            @forum_post = ForumPost.last
            assert_redirected_to(forum_topic_path(@forum_topic, page: @forum_topic.last_page, anchor: "forum_post_#{@forum_post.id}"))
          end
        end
        assert_equal(@forum_post, @ticket.model)
        assert_equal("Spam.", @ticket.reason)
        assert_equal(true, @forum_post.is_spam?)
      end

      should "not mark moderator forum posts as spam" do
        # no need to stub anything, it should return false due to Trusted+ bypassing spam checks
        assert_difference({ "User.system.tickets.count" => 0, "ForumPost.count" => 1 }) do
          post_auth forum_posts_path, @mod, params: { forum_post: { body: "abc", topic_id: @forum_topic.id } }
          @ticket = User.system.tickets.last
          @forum_post = ForumPost.last
          assert_redirected_to(forum_topic_path(@forum_topic, page: @forum_topic.last_page, anchor: "forum_post_#{@forum_post.id}"))
        end
        @forum_post = ForumPost.last
        assert_equal(false, @forum_post.is_spam?)
      end

      should "auto ban spammers" do
        SpamDetector.any_instance.stubs(:spam?).returns(true)
        as(User.system) { create_list(:ticket, SpamDetector::AUTOBAN_THRESHOLD - 1, model: @forum_post, reason: "Spam.") }
        assert_difference(%w[Ban.count User.system.tickets.count ForumPost.count], 1) do
          post_auth forum_posts_path, @user, params: { forum_post: { body: "abc", topic_id: @forum_topic.id } }
          @ticket = User.system.tickets.last
          @forum_post = ForumPost.last
          assert_redirected_to(forum_topic_path(@forum_topic, page: @forum_topic.last_page, anchor: "forum_post_#{@forum_post.id}"))
        end
        assert_equal(@forum_post, @ticket.model)
        assert_equal("Spam.", @ticket.reason)
        assert_equal(true, @forum_post.is_spam?)
        assert_equal(true, @user.reload.is_banned?)
      end

      context "mark spam action" do
        should "work and report false negative" do
          SpamDetector.any_instance.expects(:spam!).times(1)
          assert_equal(false, @forum_post.reload.is_spam?)
          put_auth mark_spam_forum_post_path(@forum_post), @mod
          assert_response(:success)
          assert_equal(true, @forum_post.reload.is_spam?)
        end

        should "work and not report false negative if ticket exists" do
          SpamDetector.any_instance.expects(:spam!).never
          User.system.tickets.create!(model: @forum_post, reason: "Spam.", creator_ip_addr: "127.0.0.1")
          assert_equal(false, @forum_post.reload.is_spam?)
          put_auth mark_spam_forum_post_path(@forum_post), @mod
          assert_response(:success)
          assert_equal(true, @forum_post.reload.is_spam?)
        end
      end

      context "mark not spam action" do
        should "work and not report false positive" do
          SpamDetector.any_instance.expects(:ham!).never
          @forum_post.update_column(:is_spam, true)
          assert_equal(true, @forum_post.reload.is_spam?)
          put_auth mark_not_spam_forum_post_path(@forum_post), @mod
          assert_response(:success)
          assert_equal(false, @forum_post.reload.is_spam?)
        end

        should "work and report false positive if ticket exists" do
          SpamDetector.any_instance.expects(:ham!).times(1)
          User.system.tickets.create!(model: @forum_post, reason: "Spam.", creator_ip_addr: "127.0.0.1")
          @forum_post.update_column(:is_spam, true)
          assert_equal(true, @forum_post.reload.is_spam?)
          put_auth mark_not_spam_forum_post_path(@forum_post), @mod
          assert_response(:success)
          assert_equal(false, @forum_post.reload.is_spam?)
        end
      end
    end
  end
end
