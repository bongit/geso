class AddMakePublicToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :make_public, :boolean
  end
end
