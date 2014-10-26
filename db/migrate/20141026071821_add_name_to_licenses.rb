class AddNameToLicenses < ActiveRecord::Migration
  def change
    add_column :licenses, :name, :string
  end
end
