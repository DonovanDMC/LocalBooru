# frozen_string_literal: true

class UploadService
  module Utils
    module_function

    class CorruptFileError < RuntimeError; end

    IMAGE_TYPES = %i[original large preview crop].freeze

    def delete_file(md5, file_ext, upload_id = nil)
      if Post.exists?(md5: md5)
        if upload_id.present? && Upload.exists?(id: upload_id)
          CurrentUser.as_system do
            Upload.find(upload_id).update(status: "completed")
          end
        end

        return
      end

      FemboyFans.config.storage_manager.delete_post_files(md5, file_ext)
    end

    def distribute_files(file, record, type, original_post_id: nil)
      # need to do this for hybrid storage manager
      post = Post.new
      post.id = original_post_id if original_post_id.present?
      post.md5 = record.md5
      post.file_ext = record.file_ext
      [FemboyFans.config.storage_manager, FemboyFans.config.backup_storage_manager].each do |sm|
        sm.store_file(file, post, type)
      end
    end

    def generate_resizes(file, upload, frame: nil)
      PostThumbnailer.generate_resizes(file, upload.image_height, upload.image_width, upload.is_video? ? :video : :image, frame: frame)
    end

    def process_file(upload, file, original_post_id: nil)
      upload.file = file
      upload.file_ext = upload.file_header_to_file_ext(file.path)
      upload.file_size = file.size
      upload.md5 = Digest::MD5.file(file.path).hexdigest

      width, height = upload.calculate_dimensions(file.path)
      upload.image_width = width
      upload.image_height = height

      upload.validate!(:file)
      upload.tag_string = "#{upload.tag_string} #{Utils.automatic_tags(upload, file)}"

      preview_file, crop_file, sample_file = Utils.generate_resizes(file, upload)

      begin
        Utils.distribute_files(file, upload, :original, original_post_id: original_post_id)
        Utils.distribute_files(sample_file, upload, :large, original_post_id: original_post_id) if sample_file.present?
        Utils.distribute_files(preview_file, upload, :preview, original_post_id: original_post_id) if preview_file.present?
        Utils.distribute_files(crop_file, upload, :crop, original_post_id: original_post_id) if crop_file.present?
      ensure
        preview_file.try(:close!)
        crop_file.try(:close!)
        sample_file.try(:close!)
      end

      # in case this upload never finishes processing, we need to delete the
      # distributed files in the future
      UploadDeleteFilesJob.set(wait: 24.hours).perform_later(upload.md5, upload.file_ext, upload.id)
    end

    def automatic_tags(upload, file)
      return "" unless FemboyFans.config.enable_autotagging?

      tags = []
      tags += %w[animated_gif animated] if upload.is_animated_gif?(file.path)
      tags += %w[animated_png animated] if upload.is_animated_png?(file.path)
      tags += ["animated"] if upload.is_video?
      tags += ["ai_generated"] if upload.is_ai_generated?(file.path)
      tags.join(" ")
    end

    def get_file_for_upload(upload, file: nil)
      return file if file.present?
      raise("No file or source URL provided") if upload.direct_url.blank?

      download = Downloads::File.new(upload.direct_url)
      download.download!
    end
  end
end
