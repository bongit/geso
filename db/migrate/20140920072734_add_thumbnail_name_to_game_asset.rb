class AddThumbnailNameToGameAsset < ActiveRecord::Migration
  def change
    add_column :game_assets, :thumbnail_name, :string
  end
end
