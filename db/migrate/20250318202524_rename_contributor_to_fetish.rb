class RenameContributorToFetish < ActiveRecord::Migration[7.1]
  def change
    rename_column(:posts, :tag_count_contributor, :tag_count_fetish)
  end
end
