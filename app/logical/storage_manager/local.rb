# frozen_string_literal: true

module StorageManager
  class Local < StorageManager::Base
    DEFAULT_PERMISSIONS = 0o644

    def store(io, dest_path)
      temp_path = "#{dest_path}-#{SecureRandom.uuid}.tmp"

      FileUtils.mkdir_p(File.dirname(temp_path))
      io.rewind
      bytes_copied = IO.copy_stream(io, temp_path)
      raise(Error, "store failed: #{bytes_copied}/#{io.size} bytes copied") if bytes_copied != io.size

      FileUtils.chmod(DEFAULT_PERMISSIONS, temp_path)
      File.rename(temp_path, dest_path)
    rescue StandardError => e
      FileUtils.rm_f(temp_path)
      raise(Error, e)
    ensure
      FileUtils.rm_f(temp_path) if temp_path
    end

    def delete(path)
      FileUtils.rm_f(path)
    end

    def open(path)
      File.open(path, "r", binmode: true)
    end

    def move_file_delete(post)
      StorageManager::IMAGE_TYPES.each do |type|
        path = file_path(post, post.file_ext, type, deleted: false)
        new_path = file_path(post, post.file_ext, type, deleted: true)
        move_file(path, new_path)
      end
      return unless post.is_video?
      FemboyFans.config.video_rescales.each_key do |k|
        %w[mp4 webm].each do |ext|
          path = file_path(post, ext, :scaled, deleted: false, scale_factor: k.to_s)
          new_path = file_path(post, ext, :scaled, deleted: true, scale_factor: k.to_s)
          move_file(path, new_path)
        end
      end
      path = file_path(post, "mp4", :original, deleted: false)
      new_path = file_path(post, "mp4", :original, deleted: true)
      move_file(path, new_path)
    end

    def move_file_undelete(post)
      StorageManager::IMAGE_TYPES.each do |type|
        path = file_path(post, post.file_ext, type, deleted: true)
        new_path = file_path(post, post.file_ext, type, deleted: false)
        move_file(path, new_path)
      end
      return unless post.is_video?
      FemboyFans.config.video_rescales.each_key do |k|
        %w[mp4 webm].each do |ext|
          path = file_path(post, ext, :scaled, deleted: true, scale_factor: k.to_s)
          new_path = file_path(post, ext, :scaled, deleted: false, scale_factor: k.to_s)
          move_file(path, new_path)
        end
      end
      path = file_path(post, "mp4", :original, deleted: true)
      new_path = file_path(post, "mp4", :original, deleted: false)
      move_file(path, new_path)
    end

    private

    def move_file(old_path, new_path)
      if File.exist?(old_path)
        FileUtils.mkdir_p(File.dirname(new_path))
        FileUtils.mv(old_path, new_path)
        FileUtils.chmod(DEFAULT_PERMISSIONS, new_path)
      end
    end
  end
end
