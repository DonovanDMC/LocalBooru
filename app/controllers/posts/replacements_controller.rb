# frozen_string_literal: true

module Posts
  class ReplacementsController < ApplicationController
    respond_to :html, :json

    content_security_policy only: %i[new] do |p|
      p.img_src(:self, :data, :blob, "*")
      p.media_src(:self, :data, :blob, "*")
    end

    def index
      params[:search][:post_id] = params.delete(:post_id) if params.key?(:post_id)
      @post_replacements = PostReplacement.includes(:post).search(search_params).paginate(params[:page], limit: params[:limit])

      respond_with(@post_replacements)
    end

    def new
      @post = Post.find(params[:post_id])
      @post_replacement = @post.replacements.new(permitted_attributes(PostReplacement))
      respond_with(@post_replacement)
    end

    def create
      @post = Post.find(params[:post_id])
      @post_replacement = @post.replacements.new(permitted_attributes(PostReplacement).merge(creator_ip_addr: CurrentUser.ip_addr))
      if @post_replacement.errors.none?
        flash.now[:notice] = "Post replacement submitted"
      end
      if @post_replacement.as_pending.to_s.falsy?
        @post_replacement.approve!
      end
      respond_to do |format|
        format.json do
          return render(json: { success: false, message: @post_replacement.errors.full_messages.join("; ") }, status: 412) if @post_replacement.errors.any?

          render(json: { success: true, location: post_path(@post) })
        end
      end
    end

    def approve
      @post_replacement = PostReplacement.find(params[:id])
      @post_replacement.approve!

      respond_with(@post_replacement, location: post_path(@post_replacement.post))
    end

    def reject
      @post_replacement = PostReplacement.find(params[:id])
      if params[:commit] != "Cancel"
        @post_replacement.reject!(CurrentUser.user)
      end

      respond_with(@post_replacement, location: post_path(@post_replacement.post))
    end

    def reject_with_reason
      @post_replacement = PostReplacement.find(params[:id])
      respond_with(@post_replacement)
    end

    def destroy
      @post_replacement = PostReplacement.find(params[:id])
      @post_replacement.destroy

      respond_with(@post_replacement, location: post_path(@post_replacement.post))
    end

    def promote
      @post_replacement = PostReplacement.find(params[:id])
      @upload = @post_replacement.promote!
      if @post_replacement.errors.any?
        respond_with(@post_replacement)
      elsif @upload.errors.any?
        respond_with(@upload)
      else
        respond_with(@upload.post)
      end
    end
  end
end
