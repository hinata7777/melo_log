class AddPostTagsCountToTags < ActiveRecord::Migration[7.2]
  def change
    add_column :tags, :post_tags_count, :integer, default: 0, null: false
  end
end
