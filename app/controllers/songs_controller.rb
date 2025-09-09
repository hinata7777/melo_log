class SongsController < ApplicationController
  def search
    q        = params[:q].to_s.strip
    per_page = 5
    page     = (params[:page] || 1).to_i.clamp(1, 4)  # 1..4（=最大20件）
    offset   = (page - 1) * per_page

    songs = q.present? ? SpotifyService.new.search(q, limit: per_page, offset: offset) : []
    
    render turbo_stream: turbo_stream.update(
      "search_results",
      partial: "songs/results",
      locals: { songs: songs, q: q, page: page, per_page: per_page }
    )
  end
end