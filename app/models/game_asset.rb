class GameAsset < ActiveRecord::Base
	# Associations
	belongs_to :user
	has_many :reviews, dependent: :destroy

	# Validations
	validates :user_id, presence: true, numericality: { only_integer: true }
	validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
	validates :license, presence: true, numericality: { only_integer: true }
	validates :main_category, presence: true, numericality: { only_integer: true }
	validate :main_category_scope
		def main_category_scope
			errors.add(:main_category, "カテゴリを選んで下さい") if 
			main_category < 0 || 4 < main_category
		end

	validates :price, numericality: { only_integer: true }
	validate :price_tier
		def price_tier
			errors.add(:price, "価格は0円、または、100円以上100,000以下で設定して下さい。") if 
			price < 0 || ( 0 < price && price < 99 ) || 100000 < price
		end
	validates :file_name, length: { maximum: 100 }
	validates :sales_copy, length: { maximum: 100 }
	validates :sales_body, length: { maximum: 1000 }
	validates :sales_closing, length: { maximum: 400 }
	validates :promo_url, 
		format: { with: /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,allow_blank: true }
	validates :make_public, :inclusion => {:in => [true, false]}
	validates :file_uploaded, :inclusion => {:in => [true, false]}
	validates :downloaded_times, numericality: { only_integer: true }

	validates :sub_category, numericality: { only_integer: true }, allow_nil: true
	validate :sub_category_scope
		def sub_category_scope
			errors.add(:sub_category, "カテゴリを選んで下さい") if 
			(sub_category != nil && sub_category < 0) || (sub_category != nil && 15 < sub_category)
		end
	validates :genre, numericality: { only_integer: true }, allow_nil: true
	validate :genre_scope
		def genre_scope
			errors.add(:genre, "ゲームジャンルを選んで下さい") if 
			(genre != nil && genre < 0) || (genre != nil && 11 < genre)
		end

	attr_accessor :file, :screenshots, :thumb

	# Serialize
	serialize :zip_includes

	# Methods
	def self.search(search_word, main_category, sub_category) #self.でクラスメソッドとしている
		if search_word
			if main_category != "" && main_category != nil
				if sub_category != "" && main_category != nil
		    		GameAsset.where(main_category: main_category).where(sub_category: sub_category).where(['name LIKE ?', "%#{search_word}%"])
		    	else
		    		GameAsset.where(main_category: main_category).where(['name LIKE ?', "%#{search_word}%"])
		    	end
			else
				GameAsset.where(['name LIKE ?', "%#{search_word}%"])
			end
		else
			if main_category != "" && main_category != nil
				if sub_category != "" && main_category != nil
		    		GameAsset.where(main_category: main_category).where(sub_category: sub_category)
		    	else
		    		GameAsset.where(main_category: main_category)
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
