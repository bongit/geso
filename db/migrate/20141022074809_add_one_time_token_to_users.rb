class AddOneTimeTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :one_time_token, :string
  end
end
