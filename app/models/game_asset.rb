class GameAsset < ActiveRecord::Base
	belongs_to :user
	validates :user_id, presence: true
	validates :price, numericality: {:only_integer => true, :greater_than_or_equal_to => 0}
	default_scope -> { order('created_at DESC') }
	attr_accessor :file
end
