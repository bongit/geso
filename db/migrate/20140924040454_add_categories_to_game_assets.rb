class AddCategoriesToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :main_category, :string
    add_column :game_assets, :sub_category, :string
  end
end
