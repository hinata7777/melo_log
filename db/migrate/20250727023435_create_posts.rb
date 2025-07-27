class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :spotify_track_id
      t.string :track_name
      t.string :artist_name
      t.string :album_image_url
      t.text :memory_text

      t.timestamps
    end
  end
end
