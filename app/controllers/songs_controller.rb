require 'ostruct'

class SongsController < ApplicationController
  def search
    # ダミーデータ（後でSpotify APIに置き換える）
    @songs = [
      OpenStruct.new(
        spotify_id: "1",
        title: "Dummy Song",
        artist: "Dummy Artist",
        album_art_url: "https://placehold.co/100x100",
        spotify_url: "https://open.spotify.com/track/dummy"
      )
    ]
    
    respond_to do |format|
      format.turbo_stream { render partial: "songs/results", locals: { songs: @songs } }
      format.html { render partial: "songs/results", locals: { songs: @songs } }
    end
  end
end