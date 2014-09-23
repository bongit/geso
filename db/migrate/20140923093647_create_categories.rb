class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.integer :game_asset_id
      t.string :main_category
      t.string :sub_category

      t.timestamps
    end
  end
end
