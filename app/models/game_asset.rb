class GameAsset < ActiveRecord::Base
	belongs_to :user
	has_many :reviews, dependent: :destroy
	validates :user_id, presence: true
	validates :price, numericality: {:only_integer => true, :greater_than_or_equal_to => 0}
	default_scope -> { order('created_at DESC') }
	attr_accessor :file, :thumbnail

	def self.search(search_word) #self.でクラスメソッドとしている
    	if search_word
    		GameAsset.where(['name LIKE ?', "%#{search_word}%"])
    	else
   			GameAsset.all #全て表示。
  		end
	end

	def increment_dt
		self.increment!(:downloaded_times, 1)
	end
end
