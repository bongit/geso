class GameAsset < ActiveRecord::Base
	belongs_to :user
	validates :user_id, presence: true
	attr_accessor :file
end
