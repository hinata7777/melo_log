class PlaylistsController < ApplicationController
  def show
    @playlist = Playlist.find_by!(slug: params[:id])
    @posts    = @playlist.posts.includes(:song, :user)
  end

  def push_to_spotify
    playlist = Playlist.find_by!(slug: params[:id])
    url = Spotify::SyncPlaylist.new(
      playlist,
      access_token: current_user.spotify_access_token,
      public: true
    ).call
    redirect_to url  # そのままSpotifyへ
  rescue => e
    redirect_to playlist_path(playlist.slug), alert: e.message
  end
end
