# frozen_string_literal: true

class FileValidator
  attr_reader :record, :file_path

  def initialize(record, file_path)
    @record = record
    @file_path = file_path
  end

  def validate
    validate_file_ext
    validate_file_integrity
    if record.is_video?
      video = record.video(file_path)
      validate_container_format(video)
      validate_colorspace(video)
      validate_sar(video) if record.is_webm?
    end
  end

  def validate_file_integrity
    if record.is_image? && record.is_corrupt?(file_path)
      record.errors.add(:file, "is corrupt")
    end
  end

  def validate_file_ext
    if FemboyFans.config.valid_file_extensions.exclude?(record.file_ext)
      record.errors.add(:file_ext, "#{record.file_ext} is invalid (only #{FemboyFans.config.valid_file_extensions.to_sentence} files are allowed)")
      throw(:abort)
    end
  end

  def validate_container_format(video)
    unless video.valid?
      record.errors.add(:base, "video isn't valid")
      return
    end
    if record.is_mp4?
      valid_video_codec = %w[h264 h265 vp9].include?(video.video_codec)
      valid_container = true
    elsif record.is_webm?
      valid_video_codec = %w[vp8 vp9 av1].include?(video.video_codec)
      valid_container = video.container == "matroska,webm"
    else
      valid_video_codec = false
      valid_container = false
    end
    unless valid_video_codec && valid_container
      record.errors.add(:base, "video container/codec isn't valid")
    end
  end

  def validate_colorspace(video)
    record.errors.add(:base, "video colorspace must be yuv420p, was #{video.colorspace}") unless video.colorspace == "yuv420p"
  end

  def validate_sar(video)
    record.errors.add(:base, "video is anamorphic (#{video.sar})") unless video.sar == "1:1"
  end
end
