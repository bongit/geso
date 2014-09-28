class AddPublicToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :public, :boolean, default: false
  end
end
