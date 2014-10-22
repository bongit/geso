class BoughtAsset < ActiveRecord::Base
	belongs_to :user
	validates :game_asset_id, :uniqueness => { :scope => :user_id }
end
