# frozen_string_literal: true

require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  context "The application controller" do
    should "return 406 Not Acceptable for a bad file extension" do
      get posts_path, params: { format: :jpg }
      assert_response 406

      get posts_path, params: { format: :blah }
      assert_response 406

      get post_path("bad.json")
      assert_response 404

      get post_path("bad.jpg")
      assert_response 406

      get post_path("bad.blah")
      assert_response 406
    end

    context "on a PaginationError" do
      should "return 410 Gone even with a bad file extension" do
        get posts_path, params: { page: 999_999_999 }, as: :json
        assert_response 410

        get posts_path, params: { page: 999_999_999 }, as: :jpg
        assert_response 410

        get posts_path, params: { page: 999_999_999 }, as: :blah
        assert_response 410
      end
    end

    context "on api authentication" do
      setup do
        @user = create(:user, password: "password")
        @api_key = create(:api_key, user: @user)

        ActionController::Base.allow_forgery_protection = true
      end

      teardown do
        ActionController::Base.allow_forgery_protection = false
      end

      context "using http basic auth" do
        should "succeed for api key matches" do
          basic_auth_string = "Basic #{::Base64.encode64("#{@user.name}:#{@api_key.key}")}"
          get edit_users_path, headers: { HTTP_AUTHORIZATION: basic_auth_string }
          assert_response :success
        end

        should "fail for api key mismatches" do
          basic_auth_string = "Basic #{::Base64.encode64("#{@user.name}:badpassword")}"
          get edit_users_path, headers: { HTTP_AUTHORIZATION: basic_auth_string }
          assert_response 401
        end

        should "succeed for non-GET requests without a CSRF token" do
          assert_changes -> { @user.reload.enable_safe_mode }, from: false, to: true do
            basic_auth_string = "Basic #{::Base64.encode64("#{@user.name}:#{@api_key.key}")}"
            post update_users_path, headers: { HTTP_AUTHORIZATION: basic_auth_string }, params: { user: { enable_safe_mode: "true" } }, as: :json
            assert_response :success
          end
        end
      end

      context "using the api_key parameter" do
        should "succeed for api key matches" do
          get edit_users_path, params: { login: @user.name, api_key: @api_key.key }
          assert_response :success
        end

        should "fail for api key mismatches" do
          get edit_users_path, params: { login: @user.name }
          assert_response 401

          get edit_users_path, params: { api_key: @api_key.key }
          assert_response 401

          get edit_users_path, params: { login: @user.name, api_key: "bad" }
          assert_response 401
        end

        should "succeed for non-GET requests without a CSRF token" do
          assert_changes -> { @user.reload.enable_safe_mode }, from: false, to: true do
            post update_users_path, params: { login: @user.name, api_key: @api_key.key, user: { enable_safe_mode: "true" } }, as: :json
            assert_response :success
          end
        end
      end

      context "without any authentication" do
        should "redirect to the login page" do
          get edit_users_path
          assert_redirected_to new_session_path(url: edit_users_path)
        end
      end

      context "with cookie-based authentication" do
        should "not allow non-GET requests without a CSRF token" do
          # get the csrf token from the login page so we can login
          get new_session_path
          assert_response :success
          token = css_select("form input[name=authenticity_token]").first["value"]

          # login
          post session_path, params: { authenticity_token: token, session: { name: @user.name, password: "password" } }
          assert_redirected_to posts_path

          # try to submit a form with cookies but without the csrf token
          post update_users_path, headers: { HTTP_COOKIE: headers["Set-Cookie"] }, params: { user: { enable_safe_mode: "true" } }
          assert_response 403
          assert_match(/ActionController::InvalidAuthenticityToken/, css_select("p").first.content)
          assert_equal(false, @user.reload.enable_safe_mode)
        end
      end
    end

    context "on session cookie authentication" do
      should "succeed" do
        user = create(:user, password: "password")

        post session_path, params: { session: { name: user.name, password: "password" } }
        get edit_users_path

        assert_response :success
      end
    end

    context "when the api limit is exceeded" do
      should "fail with a 429 error" do
        user = create(:user)
        post = create(:post, rating: "s", uploader: user)
        UserThrottle.any_instance.stubs(:throttled?).returns(true)

        put_auth post_path(post), user, params: { post: { rating: "e" } }

        assert_response 429
        assert_equal("s", post.reload.rating)
      end
    end

    context "when the user has an invalid username" do
      setup do
        @user = build(:user, name: "12345")
        @user.save(validate: false)
      end

      should "redirect for html requests" do
        get_auth posts_path, @user, params: { format: :html }
        assert_redirected_to new_user_name_change_request_path
      end

      should "not redirect for json requests" do
        get_auth posts_path, @user, params: { format: :json }
        assert_response :success
      end
    end

    context "when the user is banned" do
      setup do
        @user = create(:user)
        @user2 = create(:user)
        as(create(:admin_user)) do
          @user.bans.create!(duration: -1, reason: "Test")
          @user2.bans.create!(duration: 3, reason: "Test")
        end
      end

      context "permanently" do
        should "return a 403 for html" do
          get_auth posts_path, @user
          assert_response 403
        end

        should "return a 403 and the ban for json" do
          get_auth posts_path, @user, params: { format: :json }
          assert_response 403
          assert_equal("Account is permanently banned", @response.parsed_body["message"])
          assert_equal(@user.recent_ban.as_json, @response.parsed_body["ban"])
        end
      end

      context "temporarily" do
        should "return a 403 for html" do
          get_auth posts_path, @user2
          assert_response 403
        end

        should "return a 403 and the ban for json" do
          get_auth posts_path, @user2, params: { format: :json }
          assert_response 403
          assert_equal("Account is banned for 3 days", @response.parsed_body["message"])
          assert_equal(@user2.recent_ban.as_json, @response.parsed_body["ban"])
        end
      end
    end
  end
end
