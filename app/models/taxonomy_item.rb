class TaxonomyItem < ActiveRecord::Base
  belongs_to :parent, foreign_key: :parent_id, class_name: TaxonomyItem, required: false
end
