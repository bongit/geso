class CreateLicenses < ActiveRecord::Migration
  def change
    create_table :licenses do |t|
      t.string :type

      t.timestamps
    end
  end
end
