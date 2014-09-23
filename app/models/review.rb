class Review < ActiveRecord::Base
	belongs_to: game_asset
	belongs_to: user
end
