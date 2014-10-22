class AddPayKeyToBoughtAssets < ActiveRecord::Migration
  def change
    add_column :bought_assets, :pay_key, :string
  end
end
