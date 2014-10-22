class AddRatingToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :rating, :float
  end
end
