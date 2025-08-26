class Auth::SpotifyController < ApplicationController
  before_action :require_login

  def start
    state = SecureRandom.hex(12)
    session[:spotify_state] = state
    scope  = %w[playlist-modify-public playlist-modify-private].join(" ")

    u = URI("https://accounts.spotify.com/authorize")
    u.query = {
      response_type: "code",
      client_id:     ENV["SPOTIFY_CLIENT_ID"],
      redirect_uri:  ENV["SPOTIFY_REDIRECT_URI"],
      scope:         scope,
      state:         state
    }.to_query
    redirect_to u.to_s
  end

  def callback
    raise "state mismatch" if params[:state] != session.delete(:spotify_state)

    res = Faraday.post("https://accounts.spotify.com/api/token") do |r|
      r.headers["Content-Type"] = "application/x-www-form-urlencoded"
      r.body = {
        grant_type:   "authorization_code",
        code:         params[:code],
        redirect_uri: ENV["SPOTIFY_REDIRECT_URI"],
        client_id:    ENV["SPOTIFY_CLIENT_ID"],
        client_secret:ENV["SPOTIFY_SECRET"]
      }.to_query
    end
    b = JSON.parse(res.body)
    current_user.update!(
      spotify_access_token:  b["access_token"],
      spotify_refresh_token: b["refresh_token"],
      spotify_token_expires_at: Time.current + b["expires_in"].to_i.seconds
    )
    redirect_to my_playlists_path, notice: "Spotify連携OK"
  rescue => e
    redirect_to my_playlists_path, alert: "Spotify連携エラー: #{e.message}"
  end
end
