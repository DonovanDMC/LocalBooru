# frozen_string_literal: true

class TagsController < ApplicationController
  before_action :load_tag, except: %i[index preview meta_search]
  respond_to :html, :json

  def index
    @tags = Tag.search(search_params(Tag)).paginate(params[:page], limit: params[:limit])
    respond_with(@tags)
  end

  def preview
    @preview = TagsPreview.new(tags: params[:tags] || "")
    respond_to do |format|
      format.json do
        render(json: @preview.serializable_hash)
      end
    end
  end

  def meta_search
    @meta_search = MetaSearches::Tag.new(params)
    @meta_search.load_all
    respond_with(@meta_search)
  end

  def show
    respond_with(@tag)
  end

  def edit
    respond_with(@tag)
  end

  def update
    @tag.update(permitted_attributes(@tag))
    respond_with(@tag)
  end

  def correct
    @correction = TagCorrection.new(params[:id])
    @correction.fix!

    respond_to do |format|
      format.html { redirect_back(fallback_location: tags_path(search: { name_matches: @correction.tag.name, hide_empty: "no" }), notice: "Tag will be fixed in a few seconds") }
      format.json
    end
  end

  private

  def load_tag
    if params[:id] =~ /\A\d+\z/
      @tag = Tag.find(params[:id])
    else
      @tag = Tag.find_by!(name: params[:id])
    end
  end
end
