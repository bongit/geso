class Review < ActiveRecord::Base
	belongs_to :game_asset, :foreign_key => 'asset_id'
	belongs_to :user

	validates :game_asset_id, :uniqueness => { :scope => :reviewer_id } # unique pair of reviewer and asset
	validates :rating, numericality: { only_integer: true }
	validate :rating_scope
		def rating_scope
			errors.add(:rating, "評価は1から5までの、５段階でお願いします。") if 
			rating < 1 || 5 < rating
		end
	validates :text, length: { maximum: 400 }
	
	def self.average_rating(asset_id)
		all.where(game_asset_id: asset_id).average(:rating)
	end
end
