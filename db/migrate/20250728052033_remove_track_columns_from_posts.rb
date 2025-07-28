class RemoveTrackColumnsFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_column :posts, :spotify_track_id, :string
    remove_column :posts, :track_name, :string
    remove_column :posts, :artist_name, :string
    remove_column :posts, :album_image_url, :string
  end
end
