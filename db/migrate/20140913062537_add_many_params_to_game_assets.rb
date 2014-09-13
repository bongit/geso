class AddManyParamsToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :file_name, :string
    add_column :game_assets, :price, :integer, :null => false, :default => 0, :limit => 3
    add_column :game_assets, :sales_copy, :string
    add_column :game_assets, :sales_body, :string
    add_column :game_assets, :sales_closing, :string
    add_column :game_assets, :promo_url, :string
    add_column :game_assets, :downloaded_times, :integer, :null => false, :default => 0
    add_column :game_assets, :category_1, :string
    add_column :game_assets, :category_2, :string
    add_column :game_assets, :category_3, :string
    add_column :game_assets, :rating, :integer
    add_index :game_assets, :name
  end
end
