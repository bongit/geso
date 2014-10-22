class AddFileUploadedToGameAssets < ActiveRecord::Migration
  def change
    add_column :game_assets, :file_uploaded, :boolean
  end
end
