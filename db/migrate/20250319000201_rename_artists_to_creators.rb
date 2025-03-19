class RenameArtistsToCreators < ActiveRecord::Migration[7.1]
  def change
    rename_table(:artists, :creators)
    rename_table(:artist_versions, :creator_versions)
    rename_table(:artist_urls, :creator_urls)
    rename_column(:posts, :tag_count_artist, :tag_count_creator)
    rename_column(:creator_urls, :artist_id, :creator_id)
    rename_column(:creator_versions, :artist_id, :creator_id)
    rename_column(:pools, :artist_names, :creator_names)
    rename_column(:users, :artist_update_count, :creator_update_count)
    rename_column(:mascots, :artist_url, :creator_url)
    rename_column(:mascots, :artist_name, :creator_name)
    rename_index(:creator_urls, :index_artist_urls_on_normalized_url_pattern, :index_creator_urls_on_normalized_url_pattern)
    rename_index(:creator_urls, :index_artist_urls_on_normalized_url_trgm, :index_creator_urls_on_normalized_url_trgm)
    rename_index(:creator_urls, :index_artist_urls_on_url_trgm, :index_creator_urls_on_url_trgm)
    rename_index(:creators, :index_artists_on_name_trgm, :index_creators_on_name_trgm)
  end
end
