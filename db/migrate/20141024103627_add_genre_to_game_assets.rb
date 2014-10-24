class AddGenreToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :genre, :integer
  end
end
