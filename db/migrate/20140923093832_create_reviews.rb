class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.integer :game_asset_id
      t.integer :reviewer_id
      t.integer :rating
      t.string :text

      t.timestamps
    end
  end
end
