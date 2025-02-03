# frozen_string_literal: true

module Creators
  class UrlsController < ApplicationController
    respond_to :json, :html

    def index
      @creator_urls = CreatorUrl.includes(:creator).search(search_params(CreatorUrl)).paginate(params[:page], limit: params[:limit])
      respond_with(@creator_urls) do |format|
        format.json { render(json: @creator_urls.to_json(include: :creator)) }
      end
    end
  end
end
