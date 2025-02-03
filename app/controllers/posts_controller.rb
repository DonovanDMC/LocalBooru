# frozen_string_literal: true

class PostsController < ApplicationController
  respond_to :html, :json

  def index
    if params[:md5].present?
      @post = Post.find_by!(md5: params[:md5])
      respond_with(@post) do |format|
        format.html { redirect_to(@post) }
        format.json { render(json: [@post].to_json) }
      end
    else
      @post_set = PostSets::Post.new(tag_query, params[:page], limit: params[:limit], random: params[:random])
      @posts = PostsDecorator.decorate_collection(@post_set.posts)
      respond_with(@posts) do |format|
        format.json do
          render(json: @post_set.api_posts)
        end
      end
    end
  end

  def show
    @post = Post.find(params[:id])

    include_deleted = @post.is_deleted? || (@post.parent_id.present? && @post.parent.is_deleted?)
    @parent_post_set = PostSets::PostRelationship.new(@post.parent_id, include_deleted: include_deleted, want_parent: true)
    @children_post_set = PostSets::PostRelationship.new(@post.id, include_deleted: include_deleted, want_parent: false)

    respond_with(@post)
  end

  def show_seq
    @post = PostSearchContext.new(params).post
    include_deleted = @post.is_deleted? || (@post.parent_id.present? && @post.parent.is_deleted?)
    @parent_post_set = PostSets::PostRelationship.new(@post.parent_id, include_deleted: include_deleted, want_parent: true)
    @children_post_set = PostSets::PostRelationship.new(@post.id, include_deleted: include_deleted, want_parent: false)
    @fixup_post_url = true

    respond_with(@post) do |fmt|
      fmt.html { render("posts/show") }
    end
  end

  def update
    @post = Post.find(params[:id])

    pparams = permitted_attributes(@post)
    pparams.delete(:tag_string) if pparams[:tag_string_diff].present?
    pparams.delete(:source) if pparams[:source_diff].present?
    @post.update(pparams)
    respond_with_post_after_update(@post)
  end

  def revert
    @post = Post.find(params[:id])
    @version = @post.versions.find(params[:version_id])

    @post.revert_to!(@version)

    respond_with(@post, &:js)
  end

  def random
    tags = params[:tags] || ""
    @post = Post.tag_match("#{tags} order:random").limit(1).first
    raise(ActiveRecord::RecordNotFound) if @post.nil?
    respond_with(@post) do |format|
      format.html { redirect_to(post_path(@post, tags: params[:tags])) }
    end
  end

  def update_iqdb
    @post = Post.find(params[:id])
    @post.update_iqdb_async
    respond_with_post_after_update(@post)
  end

  def delete
    @post = Post.find(params[:id])
    @reason = ""
    @reason = "Inferior version/duplicate of post ##{@post.parent_id}" if @post.parent_id && @reason == ""
  end

  def destroy
    @post = Post.find(params[:id])
    if params[:commit] != "Cancel"
      @post.delete!(params[:reason], move_favorites: params[:move_favorites]&.truthy?)
      @post.copy_sources_to_parent if params[:copy_sources]&.truthy?
      @post.copy_tags_to_parent if params[:copy_tags]&.truthy?
      @post.parent.save if params[:copy_tags]&.truthy? || params[:copy_sources]&.truthy?
    end
    respond_with(@post) do |format|
      format.html { redirect_to(post_path(@post)) }
    end
  end

  def undelete
    @post = Post.find(params[:id])
    @post.undelete!
    respond_with(@post)
  end

  def expunge
    @post = Post.find(params[:id])
    @post.expunge!(reason: params[:reason])
    respond_with(@post)
  end

  def regenerate_thumbnails
    @post = Post.find(params[:id])
    @post.regenerate_image_samples!
    respond_with(@post)
  end

  def regenerate_videos
    @post = Post.find(params[:id])
    @post.regenerate_video_samples!
    respond_with(@post)
  end

  def add_to_pool
    @post = Post.find(params[:id])
    if params[:pool_id].present?
      @pool = Pool.find(params[:pool_id])
    else
      @pool = Pool.find_by!(name: params[:pool_name])
    end

    @pool.with_lock do
      @pool.add!(@post)
      @pool.save
    end
    append_pool_to_session(@pool)
    respond_with(@pool, location: post_path(@post))
  end

  def remove_from_pool
    @post = Post.find(params[:id])
    if params[:pool_id].present?
      @pool = Pool.find(params[:pool_id])
    else
      @pool = Pool.find_by!(name: params[:pool_name])
    end

    @pool.with_lock do
      @pool.remove!(@post)
      @pool.save
    end
    respond_with(@pool, location: post_path(@post))
  end

  def frame
    post = Post.find(params[:id])
    frame = params[:frame].to_i
    return render_expected_error(400, "Invalid frame", format: :json) if params[:frame].blank?
    post.thumbnail_frame = frame
    if post.invalid?
      return render_expected_error(400, post.errors.full_messages.join("; "), format: :json)
    end
    path = PostThumbnailer.extract_frame_from_video(post.file_path, frame)
    File.open(path, "r") do |file|
      send_data(file.read, type: "image/webp", disposition: "inline")
    end
    File.delete(path)
  end

  private

  def tag_query
    params[:tags] || (params[:post] && params[:post][:tags])
  end

  def respond_with_post_after_update(post)
    respond_with(post) do |format|
      format.html do
        if post.warnings.any?
          warnings = post.warnings.full_messages.join(".\n \n")
          flash[:notice] = warnings
        end

        if post.errors.any?
          @message = post.errors.full_messages.join("; ")
          if flash[:notice].present?
            flash[:notice] += "\n\n#{@message}"
          else
            flash[:notice] = @message
          end
        end
        response_params = { q: params[:tags_query], pool_id: params[:pool_id] }
        response_params.compact_blank!
        redirect_to(post_path(post, response_params))
      end

      format.json do
        return render_expected_error(422, post.errors.full_messages.join("; ")) if post.errors.any?
        render(json: post)
      end
    end
  end

  def append_pool_to_session(pool)
    recent_pool_ids = session[:recent_pool_ids].to_s.scan(/\d+/)
    recent_pool_ids << pool.id.to_s
    recent_pool_ids = recent_pool_ids.slice(1, 5) if recent_pool_ids.size > 5
    session[:recent_pool_ids] = recent_pool_ids.uniq.join(",")
  end
end
