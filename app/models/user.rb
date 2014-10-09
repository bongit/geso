class User < ActiveRecord::Base
	# Relations
	has_many :bought_assets
	has_many :game_assets, dependent: :destroy
	has_many :relationships, foreign_key: "follower_id", dependent: :destroy
	has_many :followed_users, through: :relationships, source: :followed
	has_many :reverse_relationships, foreign_key: "followed_id",
                                   class_name:  "Relationship",
                                   dependent:   :destroy
  	has_many :followers, through: :reverse_relationships, source: :follower

  	# Callbacks
	before_create :create_remember_token
	before_save { self.email = email.downcase }

	# Validations
	validates :name, presence: true, length: { maximum: 50}, uniqueness: 
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
	validates :email, presence:   true,
		format:     { with: VALID_EMAIL_REGEX},
		uniqueness: { case_sensitive: false}
	has_secure_password
	validates :password, length: { minimum: 6}
	validates :url, 
		format: { with: /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,allow_blank: true }
	validates :profile_text, length: { maximum: 400}

	def self.search(search_word) #self.でクラスメソッドとしている
    	if search_word
    		User.where(['name LIKE ?', "%#{search_word}%"])
    	else
   			User.all
  		end
	end

	def User.new_remember_token
		SecureRandom.urlsafe_base64
	end

	def User.encrypt(token)
		Digest::SHA1.hexdigest(token.to_s)
	end

	def feed
	end

  	def following?(other_user)
    	relationships.find_by(followed_id: other_user.id)
  	end

  	def follow!(other_user)
    	relationships.create!(followed_id: other_user.id)
  	end

  	def unfollow!(other_user)
    	relationships.find_by(followed_id: other_user.id).destroy
 	end

	private

		def create_remember_token
			self.remember_token = User.encrypt(User.new_remember_token)
		end
end
