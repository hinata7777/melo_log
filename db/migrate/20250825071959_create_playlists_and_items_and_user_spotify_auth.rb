class CreatePlaylistsAndItemsAndUserSpotifyAuth < ActiveRecord::Migration[7.2]
  def change
    create_table :playlists do |t|
      t.references :user, foreign_key: true
      t.references :tag,  foreign_key: true     
      t.string  :title, null: false
      t.string  :slug,  null: false            
      t.integer :generated_by, null: false, default: 0  # 0:user 1:tag 2:admin
      t.boolean :public, null: false, default: true
      t.string  :spotify_playlist_id             
      t.string  :spotify_url                     
      t.timestamps
    end
    add_index :playlists, :slug, unique: true
    add_index :playlists, :spotify_playlist_id, unique: true

    create_table :playlist_items do |t|
      t.references :playlist, null: false, foreign_key: true
      t.references :post,     null: false, foreign_key: true
      t.integer :position,    null: false
      t.timestamps
    end
    add_index :playlist_items, [:playlist_id, :post_id], unique: true
    add_index :playlist_items, [:playlist_id, :position], unique: true

    add_column :users, :spotify_access_token, :string unless column_exists?(:users, :spotify_access_token)
    add_column :users, :spotify_refresh_token, :string unless column_exists?(:users, :spotify_refresh_token)
    add_column :users, :spotify_token_expires_at, :datetime unless column_exists?(:users, :spotify_token_expires_at)
    add_index  :users, :spotify_access_token unless index_exists?(:users, :spotify_access_token)
  end
end
