require 'ostruct'

class SongsController < ApplicationController
  def search
    query = params[:q]
    @songs = query.present? ? SpotifyService.search(query) : []

    render partial: "songs/results", locals: { songs: @songs }
  end
end

