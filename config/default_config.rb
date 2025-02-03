# frozen_string_literal: true

module FemboyFans
  class Configuration
    def version
      GitHelper.short_hash
    end

    def app_name
      "LocalBooru"
    end

    def app_url
      "https://#{domain}"
    end

    def description
      "A localized stripped-down booru for personal use."
    end

    def domain
      "booru.local"
    end

    def cdn_domain
      domain
    end

    # The canonical hostname of the site.
    def hostname
      Socket.gethostname
    end

    def source_code_url
      "https://github.com/DonovanDMC/LocalBooru"
    end

    # Stripped of any special characters.
    def safe_app_name
      app_name.gsub(/[^a-zA-Z0-9_-]/, "_")
    end

    def user_timezone
      "Central Time (US & Canada)"
    end

    def statement_timeout
      10_000
    end

    def per_page
      100
    end

    def enable_keyboard_navigation?
      true
    end

    def enable_autocomplete?
      true
    end

    def style_usernames?
      true
    end

    def enable_hover_zoom?
      true
    end

    def hover_zoom_shift?
      true
    end

    def hover_zoom_sticky_shift?
      true
    end

    def hover_zoom_play_audio?
      false
    end

    def default_image_size
      "original"
    end

    def safeblocked_tags
      []
    end

    # This allows using statically linked copies of ffmpeg in non default locations. Not universally supported across
    # the codebase at this time.
    def ffmpeg_path
      "/usr/bin/ffmpeg"
    end

    # Thumbnail size
    def small_image_width
      300
    end

    # Large resize image width. Set to nil to disable.
    def large_image_width
      850
    end

    def large_image_prefix
      ""
    end

    def deleted_path_prefix
      "deleted"
    end

    def replacement_path_prefix
      "replacements"
    end

    def deleted_preview_url
      "/images/deleted-preview.png"
    end

    # When calculating statistics based on the posts table, gather this many posts to sample from.
    def post_sample_size
      300
    end

    def disable_cache_store?
      true
    end

    def remember_key
      "abc123"
    end

    # After this many pages, the paginator will switch to sequential mode.
    def max_numbered_pages
      5_000
    end

    def max_per_page
      500
    end

    def move_related_thumbnails?
      false
    end

    def top_notices?
      true
    end

    def valid_file_extensions
      %w[jpg png webp gif webm mp4]
    end

    # Permanently redirect all HTTP requests to HTTPS.
    #
    # https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
    # http://api.rubyonrails.org/classes/ActionDispatch/SSL.html
    def ssl_options
      {
        redirect: { exclude: ->(request) { request.subdomain == "insecure" } },
        hsts:     {
          expires:    1.year,
          preload:    true,
          subdomains: false,
        },
      }
    end

    # The method to use for storing image files.
    def storage_manager
      # Store files on the local filesystem.
      # base_dir - where to store files (default: under public/data)
      # base_url - where to serve files from (default: http://#{hostname}/data)
      # hierarchical: false - store files in a single directory
      # hierarchical: true - store files in a hierarchical directory structure, based on the MD5 hash
      StorageManager::Local.new(base_dir: Rails.public_path.join("data").to_s, hierarchical: true)
      # StorageManager::Ftp.new(ftp_hostname, ftp_port, ftp_username, ftp_password, base_dir: "", base_path: "", base_url: "https://static.femboy.fan", hierarchical: true)

      # Select the storage method based on the post's id and type (preview, large, or original).
      # StorageManager::Hybrid.new do |id, md5, file_ext, type|
      #   if type.in?([:large, :original]) && id.in?(0..850_000)
      #     StorageManager::Local.new(base_dir: "/path/to/files", hierarchical: true)
      #   else
      #     StorageManager::Local.new(base_dir: "/path/to/files", hierarchical: true)
      #   end
      # end
    end

    # The method to use for backing up image files.
    def backup_storage_manager
      # Don't perform any backups.
      StorageManager::Null.new

      # Backup files to /mnt/backup on the local filesystem.
      # StorageManager::Local.new(base_dir: "/mnt/backup", hierarchical: false)
    end

    # Any custom code you want to insert into the default layout without
    # having to modify the templates.
    def custom_html_header_content
      nil
    end

    def enable_autotagging?
      true
    end

    # The default headers to be sent with outgoing http requests. Some external
    # services will fail if you don't set a valid User-Agent.
    def http_headers
      {
        user_agent: "#{safe_app_name}/#{version} (https://github.com/DonovanDMC/LocalBooru)",
      }
    end

    # https://lostisland.github.io/faraday/#/customization/connection-options
    def faraday_options
      {
        request: {
          timeout:      10,
          open_timeout: 10,
        },
        headers: http_headers,
      }
    end

    def iqdb_server
    end

    def opensearch_host
    end

    def enable_image_cropping?
      false
    end

    def redis_url
    end

    # Additional video samples will be generated in these dimensions if it makes sense to do so
    # They will be available as additional scale options on applicable posts in the order they appear here
    def video_rescales
      {} # { "720p" => [1280, 720], "480p" => [640, 480] }
    end

    def image_rescales
      []
    end

    def show_tag_scripting?(_user)
      true
    end

    def show_backtrace?(_user, _backtrace)
      true
    end

    # Prevents Aliases/BURs from copying non-general categories from antecedent tags to large consequent tags
    def alias_category_change_cutoff
      10_000
    end
  end

  class EnvironmentConfiguration
    def custom_configuration
      @custom_configuration ||= CustomConfiguration.new
    end

    def env_to_boolean(method, var)
      is_boolean = method.to_s.end_with?("?")
      return true if is_boolean && var.truthy?
      return false if is_boolean && var.falsy?
      var
    end

    def method_missing(method, *)
      var = ENV.fetch("FEMBOYFANS_#{method.to_s.upcase.chomp('?')}", nil)

      if var.present?
        env_to_boolean(method, var)
      else
        custom_configuration.send(method, *)
      end
    end
  end

  def config
    @config ||= EnvironmentConfiguration.new
  end

  module_function :config
end
