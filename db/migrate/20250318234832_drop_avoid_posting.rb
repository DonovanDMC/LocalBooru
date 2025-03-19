class DropAvoidPosting < ActiveRecord::Migration[7.1]
  def change
    drop_table(:avoid_posting_versions)
    drop_table(:avoid_postings)
  end
end
