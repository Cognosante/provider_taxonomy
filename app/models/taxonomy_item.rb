class TaxonomyItem < ActiveRecord::Base
  belongs_to :parent, foreign_key: :parent_id, class_name: TaxonomyItem, required: false
  scope :categorized, -> { where.not(category: nil) }
  DEPTHS = {
    provider_types:   1,
    specialties:      2,
    sub_specialties:  3
  }.freeze

  class << self
    def provider_types
      TaxonomyItem.where(depth: DEPTHS[:provider_types])
    end

    def specialties
      TaxonomyItem.where(depth: DEPTHS[:specialties])
    end

    def sub_specialties
      TaxonomyItem.where(depth: DEPTHS[:sub_specialties])
    end

    def search_by_name(query)
      sql = TaxonomyItem.all
      sql = sql.where('name ILIKE ?', "%#{query}%") if query.present?

      sql
    end
  end
end
