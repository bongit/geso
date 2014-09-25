class RemoveThumbnailNameFromGameAssets < ActiveRecord::Migration
  def change
    remove_column :game_assets, :thumbnail_name, :string
  end
end
