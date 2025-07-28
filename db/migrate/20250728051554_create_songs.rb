class CreateSongs < ActiveRecord::Migration[7.2]
  def change
    create_table :songs do |t|
      t.string :spotify_id
      t.string :title
      t.string :artist
      t.string :album_art_url
      t.string :spotify_url

      t.timestamps
    end
  end
end
