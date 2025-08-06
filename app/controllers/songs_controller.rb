require 'ostruct'

class SongsController < ApplicationController
  skip_before_action :require_login, only: [:search]
  
  def search
    query = params[:q]
    @songs = query.present? ? SpotifyService.search(query) : []

    render partial: "songs/results", locals: { songs: @songs }
  end
end