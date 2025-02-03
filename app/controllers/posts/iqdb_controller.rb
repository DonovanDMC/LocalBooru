# frozen_string_literal: true

module Posts
  class IqdbController < ApplicationController
    respond_to :html, :json
    # Show uses POST because it needs a file parameter. This would be GET otherwise.
    skip_forgery_protection only: :show
    before_action :validate_enabled

    def show
      # Allow legacy ?post_id=123 parameters
      search_params = params[:search].presence || params

      @matches = []
      if search_params[:file].present?
        if search_params[:file].is_a?(ActionDispatch::Http::UploadedFile)
          @matches = IqdbProxy.query_file(search_params[:file].tempfile, search_params[:score_cutoff])
        else
          return render_expected_error(400, "Invalid file")
        end
      elsif search_params[:url].present?
        parsed_url = begin
          Addressable::URI.heuristic_parse(search_params[:url])
        rescue StandardError
          nil
        end
        raise(User::PrivilegeError, "Invalid URL") unless parsed_url
        @matches = IqdbProxy.query_url(search_params[:url], search_params[:score_cutoff])
      elsif search_params[:post_id].present?
        @matches = IqdbProxy.query_post(Post.find_by(id: search_params[:post_id]), search_params[:score_cutoff])
      elsif search_params[:hash].present?
        @matches = IqdbProxy.query_hash(search_params[:hash], search_params[:score_cutoff])
      end

      respond_with(@matches) do |fmt|
        fmt.json do
          render(json: @matches)
        end
      end
    rescue IqdbProxy::Error => e
      render_expected_error(500, e.message)
    end

    def validate_enabled
      raise(FeatureUnavailable) unless IqdbProxy.enabled?
    end
  end
end
