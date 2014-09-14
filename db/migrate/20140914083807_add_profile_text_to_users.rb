class AddProfileTextToUsers < ActiveRecord::Migration
  def change
    add_column :users, :profile_text, :string
  end
end
