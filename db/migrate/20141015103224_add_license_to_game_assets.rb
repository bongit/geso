class AddLicenseToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :license, :integer
  end
end
