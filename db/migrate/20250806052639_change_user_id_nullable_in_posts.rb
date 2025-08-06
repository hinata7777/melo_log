class ChangeUserIdNullableInPosts < ActiveRecord::Migration[7.2]
  def change
    change_column_null :posts, :user_id, true
  end
end