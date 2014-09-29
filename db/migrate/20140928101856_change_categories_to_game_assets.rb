class ChangeCategoriesToGameAssets < ActiveRecord::Migration
  def change
  	change_column :game_assets, :main_category, :integer
  	change_column :game_assets, :sub_category, :integer
  end
end
