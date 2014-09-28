class GameAsset < ActiveRecord::Base
	# Associations
	belongs_to :user
	has_many :reviews, dependent: :destroy
	has_many :categories

	# Validations
	validates :user_id, presence: true
	validates :price, numericality: {:only_integer => true, :greater_than_or_equal_to => 0}

	# Scope
	default_scope -> { order('created_at DESC') }

	attr_accessor :file, :screenshots, :thumbnail
	
	# Methods
	def self.search(search_word, main_category) #self.でクラスメソッドとしている
    	if search_word && main_category
    		GameAsset.where(main_category: main_category).where(['name LIKE ?', "%#{search_word}%"])
    	elsif search_word && main_category == nil
    		GameAsset.where(['name LIKE ?', "%#{search_word}%"])
    	elsif search_word == nil && main_category
    		GameAsset.where(main_category: main_category)
    	else
   			GameAsset.all #全て表示。
  		end
	end

	def increment_dt
		self.increment!(:downloaded_times, 1)
	end
end
