# frozen_string_literal: true

class UploadService
  attr_reader :params, :post, :upload

  def initialize(params)
    @params = params
  end

  def start!
    params[:tag_string] ||= "tagme"
    @upload = Upload.create(params)

    begin
      if @upload.invalid?
        return @upload
      end

      @upload.update(status: "processing")

      @upload.file = Utils.get_file_for_upload(@upload, file: @upload.file)
      Utils.process_file(upload, @upload.file)

      @upload.save!
      @post = create_post_from_upload(@upload)
      @upload
    rescue Exception => e
      Rails.logger.error(e)
      @upload.update(status: "error: #{e.class} - #{e.message}", backtrace: e.backtrace.join("\n"))
      @upload
    end
  end

  def warnings
    return [] if @post.nil?
    @post.warnings.full_messages
  end

  def create_post_from_upload(upload)
    @post = convert_to_post(upload)
    @post.save!
    @post.reload

    upload.update(status: "completed", post_id: @post.id)

    @post
  end

  def convert_to_post(upload)
    Post.new.tap do |p|
      p.tag_string = upload.tag_string
      p.original_tag_string = upload.tag_string
      p.description = upload.description.strip
      p.md5 = upload.md5
      p.file_ext = upload.file_ext
      p.image_width = upload.image_width
      p.image_height = upload.image_height
      p.rating = upload.rating
      p.source = upload.source
      p.file_size = upload.file_size
      p.uploader_ip_addr = upload.uploader_ip_addr
      p.parent_id = upload.parent_id
      p.has_cropped = upload.is_image?
      p.duration = upload.video_duration(upload.file.path)
      p.framecount = upload.video_framecount(upload.file.path)
      p.upload_url = upload.direct_url
    end
  end
end
