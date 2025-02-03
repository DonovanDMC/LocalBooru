# frozen_string_literal: true

module Pools
  class OrdersController < ApplicationController
    respond_to :html, :json, :js

    def edit
      @pool = Pool.find(params[:pool_id])
      respond_with(@pool)
    end
  end
end
