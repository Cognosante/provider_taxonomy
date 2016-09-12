require 'rails_helper'

RSpec.describe TaxonomyItem, type: :model do
  it 'should have some items' do
    expect(TaxonomyItem.count).to eq(912)
  end

  it 'should filter by depth' do
    expect(TaxonomyItem.provider_types.count).to eq(29)
    expect(TaxonomyItem.specialties.count).to eq(244)
    expect(TaxonomyItem.sub_specialties.count).to eq(611)
  end

  it 'should be categorized' do
    expect(TaxonomyItem.categorized.count).to be > 0
  end

  it 'should have parents' do
    dental_prov = TaxonomyItem.where(name: 'Dental Providers').first
    dentist = TaxonomyItem.where(name: 'Dentist').first
    expect(dentist.parent_id).to eq(dental_prov.id)
  end
end
