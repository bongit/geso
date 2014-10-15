class AddLisenceToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :lisence, :integer
  end
end
