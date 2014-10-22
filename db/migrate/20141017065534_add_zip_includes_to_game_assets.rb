class AddZipIncludesToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :zip_includes, :text
  end
end
