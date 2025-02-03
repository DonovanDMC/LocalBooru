# frozen_string_literal: true

module Pools
  class VersionsController < ApplicationController
    respond_to :html, :json

    def index
      if (pool_id = params.dig(:search, :pool_id)).present?
        @pool = Pool.find_by(id: pool_id)
      end

      @pool_versions = PoolVersion.search(search_params(PoolVersion)).paginate(params[:page], limit: params[:limit])
      respond_with(@pool_versions)
    end

    def diff
      @pool_version = PoolVersion.find(params[:id])
    end
  end
end
