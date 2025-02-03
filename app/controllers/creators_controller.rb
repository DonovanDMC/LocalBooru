# frozen_string_literal: true

class CreatorsController < ApplicationController
  before_action :load_creator, only: %i[edit update destroy revert]
  respond_to :html, :json

  def index
    if params[:name].present?
      @creator = Creator.find_by(name: Creator.normalize_name(params[:id]))
      if @creator.nil?
        return redirect_to(show_or_new_creators_path(name: params[:id])) if request.format.html?
        raise(ActiveRecord::RecordNotFound)
      end
      redirect_to(creator_path(@creator))
    end
    @creators = Creator.includes(:urls).search(search_params(Creator)).paginate(params[:page], limit: params[:limit])
    respond_with(@creators) do |format|
      format.json do
        render(json: @creators.to_json(include: %i[urls]))
        expires_in(params[:expiry].to_i.days) if params[:expiry]
      end
    end
  end

  def show
    if params[:id] =~ /\A\d+\z/
      @creator = Creator.find(params[:id])
    else
      @creator = Creator.named(name: params[:id])
      unless @creator
        respond_to do |format|
          format.html do
            redirect_to(show_or_new_creators_path(name: params[:id]))
          end
          format.json do
            raise(ActiveRecord::RecordNotFound)
          end
        end
        return
      end
    end
    @post_set = PostSets::Post.new(@creator.name, 1, limit: 10)
    respond_with(@creator, methods: %i[domains], include: %i[urls])
  end

  def new
    @creator = Creator.new(permitted_attributes(Creator))
    respond_with(@creator)
  end

  def edit
    respond_with(@creator)
  end

  def create
    @creator = Creator.new(permitted_attributes(Creator))
    @creator.save
    respond_with(@creator)
  end

  def update
    @creator.update(permitted_attributes(@creator))
    notice(@creator.valid? ? "Creator updated" : @creator.errors.full_messages.join("; "))
    respond_with(@creator)
  end

  def destroy
    @creator.destroy
    respond_with(@creator) do |format|
      format.html do
        redirect_to(creators_path, notice: @creator.destroyed? ? "Creator deleted" : @creator.errors.full_messages.join("; "))
      end
    end
  end

  def revert
    @version = @creator.versions.find(params[:version_id])
    @creator.revert_to!(@version)
    respond_with(@creator)
  end

  def show_or_new
    @creator = Creator.named(params[:name])
    if @creator
      redirect_to(creator_path(@creator))
    else
      @creator = Creator.new(name: Creator.normalize_name(params[:name] || ""))
      @post_set = PostSets::Post.new(@creator.name, 1, limit: 10)
      respond_with(@creator)
    end
  end

  private

  def load_creator
    if params[:id] =~ /\A\d+\z/
      @creator = Creator.find(params[:id])
    else
      @creator = Creator.named(name: params[:id])
      raise(ActiveRecord::RecordNotFound) if @creator.blank?
    end
  end
end
