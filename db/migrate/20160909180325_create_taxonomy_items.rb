class CreateTaxonomyItems < ActiveRecord::Migration[5.0]
  def change
    create_table :taxonomy_items do |t|
      t.string :name, null: false
      t.integer :parent_id
      t.integer :depth
      t.string :category
      t.string :taxonomy_code
      t.string :sub_category
      t.string :definition
      t.string :notes
    end
    add_index :taxonomy_items, :parent_id
  end
end
