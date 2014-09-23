class RemoveSeparatedCategoriesFromGameAssets < ActiveRecord::Migration
  def change
    remove_column :game_assets, :category_1, :string
    remove_column :game_assets, :category_2, :string
    remove_column :game_assets, :category_3, :string
  end
end
