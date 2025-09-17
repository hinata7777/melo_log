class SongsController < ApplicationController
  def search
    q = params[:q].to_s.strip
    songs = q.present? ? SpotifyService.search(q) : []

    render turbo_stream: turbo_stream.update(
      "search_results",
      partial: "songs/results",
      locals: { songs: songs, q: q }
    )
  end
end
