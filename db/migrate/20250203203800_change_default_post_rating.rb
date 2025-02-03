class ChangeDefaultPostRating < ActiveRecord::Migration[7.1]
  def change
    change_column_default(:posts, :rating, from: "q", to: "a")
  end
end
