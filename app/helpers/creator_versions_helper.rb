# frozen_string_literal: true

module CreatorVersionsHelper
  def creator_versions_listing_type
    params.dig(:search, :creator_id).present? ? :revert : :standard
  end

  def creator_version_other_names_diff(creator_version)
    new_names = creator_version.other_names
    old_names = creator_version.previous.try(:other_names)
    if creator_version.creator.present?
      latest_names = creator_version.creator.other_names
    else
      latest_names = new_names
    end

    diff_list_html(new_names, old_names, latest_names)
  end

  def creator_version_urls_diff(creator_version)
    new_urls = creator_version.urls
    old_urls = creator_version.previous.try(:urls)
    if creator_version.creator.present?
      latest_urls = creator_version.creator.urls.map(&:to_s)
    else
      latest_urls = new_urls
    end

    diff_list_html(new_urls, old_urls, latest_urls)
  end
end
