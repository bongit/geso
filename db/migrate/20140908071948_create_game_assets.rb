class CreateGameAssets < ActiveRecord::Migration
  def change
    create_table :game_assets do |t|
      t.string :name
      t.integer :user_id

      t.timestamps
    end
  end
end
