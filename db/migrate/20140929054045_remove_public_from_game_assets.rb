class RemovePublicFromGameAssets < ActiveRecord::Migration
  def change
  	    remove_column :game_assets, :public, :boolean
  end
end
