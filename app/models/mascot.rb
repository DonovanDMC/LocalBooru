# frozen_string_literal: true

class Mascot < ApplicationRecord
  belongs_to_creator

  array_attribute :available_on, parse: /[^,]+/, join_character: ","
  attr_accessor :mascot_file

  validates :display_name, :background_color, :artist_url, :artist_name, presence: true
  validates :artist_url, format: { with: %r{\Ahttps?://}, message: "must start with http:// or https://" }, length: { maximum: 1_000 }
  validates :display_name, :artist_name, length: { maximum: 100 }
  validates :mascot_file, presence: true, on: :create
  validate :set_file_properties
  validates :md5, uniqueness: true
  validate if: :mascot_file do |mascot|
    FileValidator.new(mascot, mascot_file.path).validate(max_file_sizes: FemboyFans.config.max_mascot_file_sizes, max_width: FemboyFans.config.max_mascot_width, max_height: FemboyFans.config.max_mascot_height)
  end

  after_create :log_create
  after_update :log_update
  after_destroy :log_delete
  after_commit :invalidate_cache
  after_save_commit :write_storage_file
  after_destroy_commit :remove_storage_file

  def set_file_properties
    return if mascot_file.blank?

    self.file_ext = file_header_to_file_ext(mascot_file.path)
    self.md5 = Digest::MD5.file(mascot_file.path).hexdigest
  end

  def write_storage_file
    return if mascot_file.blank?

    FemboyFans.config.storage_manager.delete_mascot(md5_previously_was, file_ext_previously_was)
    FemboyFans.config.storage_manager.store_mascot(mascot_file, self)
  end

  def self.active_for_browser
    mascots = Cache.fetch("active_mascots", expires_in: 1.day) do
      query = Mascot.where(active: true).where("? = ANY(available_on)", FemboyFans.config.app_name)
      mascots = query.map do |mascot|
        mascot.slice(:id, :background_color, :artist_url, :artist_name, :hide_anonymous).merge(background_url: mascot.url_path)
      end
      mascots.index_by { |mascot| mascot["id"] }
    end
    if CurrentUser.user.nil? || CurrentUser.user.is_anonymous?
      mascots.each_pair do |id, mascot|
        mascots.delete(id) if mascot[:hide_anonymous]
      end
    end
    mascots
  end

  def invalidate_cache
    Cache.delete("active_mascots")
  end

  def remove_storage_file
    FemboyFans.config.storage_manager.delete_mascot(md5, file_ext)
  end

  def url_path
    FemboyFans.config.storage_manager.mascot_url(self)
  end

  def file_path
    FemboyFans.config.storage_manager.mascot_path(self)
  end

  concerning :ValidationMethods do
    def dimensions
      @dimensions ||= calculate_dimensions(mascot_file.path)
    end

    def image_width
      dimensions[0]
    end

    def image_height
      dimensions[1]
    end

    def file_size
      @file_size ||= FemboyFans.config.storage_manager.open(mascot_file.path).size
    end
  end

  def self.search(params)
    q = super
    q.order("lower(artist_name)")
  end

  module LogMethods
    def log_create
      ModAction.log!(:mascot_create, self)
    end

    def log_update
      ModAction.log!(:mascot_update, self)
    end

    def log_delete
      ModAction.log!(:mascot_delete, self)
    end
  end

  include FileMethods
  include LogMethods

  def self.available_includes
    %i[creator]
  end
end
