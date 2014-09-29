class SubCategory < ActiveRecord::Base
	belongs_to :main_category, :foreign_key => 'parent_id'

	def self.sub_for(main_category)
		SubCategory.where(parent_id: main_category)
	end
end
