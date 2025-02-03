# frozen_string_literal: true

class UploadsController < ApplicationController
  respond_to :html, :json
  content_security_policy only: [:new] do |p|
    p.img_src(:self, :data, :blob, "*")
    p.media_src(:self, :data, :blob, "*")
  end

  def index
    @uploads = Upload.search(search_params(Upload)).includes(:post).paginate(params[:page], limit: params[:limit])
    respond_with(@uploads)
  end

  def show
    @upload = Upload.find(params[:id])
    respond_with(@upload) do |format|
      format.html do
        if @upload.is_completed? && @upload.post_id
          redirect_to(post_path(@upload.post_id))
        end
      end
    end
  end

  def new
    @upload = Upload.new
    respond_with(@upload)
  end

  def create
    Post.transaction do
      @service = UploadService.new(permitted_attributes(Upload).merge(uploader_ip_addr: CurrentUser.ip_addr))
      @upload = @service.start!
    end

    if @upload.invalid?
      flash.now[:notice] = @upload.errors.full_messages.join("; ")
      return render(json: { success: false, reason: "invalid", message: @upload.errors.full_messages.join("; ") }, status: 412)
    end
    if @service.warnings.any? && !@upload.is_errored? && !@upload.is_duplicate?
      warnings = @service.warnings.join(".\n \n")
      flash.now[:notice] = warnings
    end

    respond_to do |format|
      format.json do
        return render(json: { success: false, reason: "duplicate", location: post_path(@upload.duplicate_post_id), post_id: @upload.duplicate_post_id }, status: 412) if @upload.is_duplicate?
        return render(json: { success: false, reason: "invalid", message: @upload.sanitized_status }, status: 412) if @upload.is_errored?

        render(json: { success: true, location: post_path(@upload.post_id), post_id: @upload.post_id })
      end
    end
  end
end
