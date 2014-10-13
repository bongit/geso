class GameAsset < ActiveRecord::Base
	# Associations
	belongs_to :user
	has_many :reviews, dependent: :destroy
	has_many :categories

	# Validations
	validates :user_id, presence: true
	validates :price, numericality: {:only_integer => true, :greater_than_or_equal_to => 0, :less_than => 100000}

	attr_accessor :file, :screenshots, :thumbnail
	
	# Methods
	def self.search(search_word, main_category, sub_category) #self.でクラスメソッドとしている
		if search_word
			if main_category != "" && main_category != nil
				if sub_category != "" && main_category != nil
		    		GameAsset.where(make_public: 1).where(main_category: main_category).where(sub_category: sub_category).where(['name LIKE ?', "%#{search_word}%"])
		    	else
		    		GameAsset.where(make_public: 1).where(main_category: main_category).where(['name LIKE ?', "%#{search_word}%"])
		    	end
			else
				GameAsset.where(make_public: 1).where(['name LIKE ?', "%#{search_word}%"])
			end
		else
			if main_category != "" && main_category != nil
				if sub_category != "" && main_category != nil
		    		GameAsset.where(make_public: 1).where(main_category: main_category).where(sub_category: sub_category)
		    	else
		    		GameAsset.where(make_public: 1).where(main_category: main_category)
		    	end
			else
				GameAsset.all
			end
		end
	end

	def increment_dt
		self.increment!(:downloaded_times, 1)
	end
end
