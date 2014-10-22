class RemoveRatingFromGameAssets < ActiveRecord::Migration
  def change
    remove_column :game_assets, :rating, :integer
  end
end
