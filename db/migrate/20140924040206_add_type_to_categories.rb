class AddTypeToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :type, :string
    remove_column :categories, :main_category, :string
    remove_column :categories, :sub_category, :string
  end
end
