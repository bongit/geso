class Cart < ActiveRecord::Base
	belongs_to :user
	has_many :game_asset

	validates :asset_id, :uniqueness => { :scope => :user_id }

end
