class AddCategoryToTags < ActiveRecord::Migration[7.2]
  def change
    add_column :tags, :category, :integer, null: false, default: 0
    add_index  :tags, :category
  end
end
