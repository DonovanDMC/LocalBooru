# frozen_string_literal: true

module Creators
  class VersionsController < ApplicationController
    respond_to :html, :json

    def index
      @creator_versions = CreatorVersion.search(search_params(CreatorVersion)).paginate(params[:page], limit: params[:limit])
      respond_with(@creator_versions)
    end
  end
end
