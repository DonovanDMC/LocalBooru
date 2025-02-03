# frozen_string_literal: true

module Posts
  class EventsController < ApplicationController
    respond_to :html, :json

    def index
      @events = PostEventDecorator.decorate_collection(
        PostEvent.search(search_params(PostEvent)).paginate(params[:page], limit: params[:limit]),
      )
      respond_with(@events) do |format|
        format.json do
          render(json: Draper.undecorate(@events))
        end
      end
    end
  end
end
