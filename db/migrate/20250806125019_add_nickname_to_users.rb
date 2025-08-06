class AddNicknameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :nickname, :string, null: false
  end
end
