class AddSongIdToPosts < ActiveRecord::Migration[7.2]
  def change
    add_reference :posts, :song, null: false, foreign_key: true
  end
end
