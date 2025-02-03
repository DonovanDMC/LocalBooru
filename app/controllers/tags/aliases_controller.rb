# frozen_string_literal: true

module Tags
  class AliasesController < ApplicationController
    respond_to :html, :json
    wrap_parameters :tag_alias

    def index
      @tag_aliases = TagAlias.includes(:antecedent_tag, :consequent_tag).search(search_params(TagAlias)).paginate(params[:page], limit: params[:limit])
      respond_with(@tag_aliases)
    end

    def show
      @tag_alias = TagAlias.find(params[:id])
      respond_with(@tag_alias)
    end

    def new
      @tag_alias = TagAlias.new
    end

    def edit
      @tag_alias = TagAlias.find(params[:id])
    end

    def create
      @tag_alias_request = TagAliasRequest.new(**permitted_attributes(TagAlias).to_h.symbolize_keys)
      @tag_alias_request.create

      if @tag_alias_request.invalid?
        respond_with(@tag_alias_request) do |format|
          format.html { redirect_back(fallback_location: new_tag_alias_path, notice: @tag_alias_request.errors.full_messages.join("; ")) }
        end
      else
        respond_with(@tag_alias_request.tag_relationship)
      end
    end

    def update
      @tag_alias = TagAlias.find(params[:id])

      if @tag_alias.is_pending? && @tag_alias.editable_by?(CurrentUser.user)
        @tag_alias.update(permitted_attributes(@tag_alias))
      end

      respond_with(@tag_alias)
    end

    def destroy
      @tag_alias = TagAlias.find(params[:id])
      @tag_alias.reject!(CurrentUser.user)
      respond_with(@tag_alias, location: tag_aliases_path)
    end

    def approve
      @tag_alias = TagAlias.find(params[:id])
      @tag_alias.approve!(CurrentUser.user)
      respond_with(@tag_alias, location: tag_alias_path(@tag_alias))
    end
  end
end
