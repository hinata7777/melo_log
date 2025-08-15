class AddResetPasswordToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_token_expires_at, :datetime
    add_column :users, :reset_password_email_sent_at, :datetime

    add_index :users, :reset_password_token
  end
end
