class AddPayKeyToCarts < ActiveRecord::Migration
  def change
    add_column :carts, :pay_key, :string
  end
end
