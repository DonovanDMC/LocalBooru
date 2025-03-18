class RenameFetishToKink < ActiveRecord::Migration[7.1]
  def change
    rename_column(:posts, :tag_count_fetish, :tag_count_kink)
  end
end
