class CreateBoughtAssets < ActiveRecord::Migration
  def change
    create_table :bought_assets do |t|
      t.integer :user_id
      t.integer :game_asset_id

      t.timestamps
    end
  end
end
