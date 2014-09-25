class RemoveGameAssetIdFromCategories < ActiveRecord::Migration
  def change
    remove_column :categories, :game_asset_id, :integer
  end
end
