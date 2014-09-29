class CreateSubCategories < ActiveRecord::Migration
  def change
    create_table :sub_categories do |t|
      t.string :name
      t.integer :parent_id

      t.timestamps
    end
  end
end
