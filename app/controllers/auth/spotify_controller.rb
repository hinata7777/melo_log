class Auth::SpotifyController < ApplicationController
  before_action :require_login

  def start
    state = SecureRandom.hex(16)
    session[:spotify_state] = state
    session[:return_to] = params[:return_to].presence || session[:return_to] || request.referer

    scope = %w[playlist-modify-public playlist-modify-private].join(" ")

    u = URI("https://accounts.spotify.com/authorize")
    u.query = {
      response_type: "code",
      client_id:     ENV.fetch("SPOTIFY_CLIENT_ID"),
      redirect_uri:  callback_uri,  # ← 登録済みのURIと完全一致
      scope:         scope,
      state:         state
    }.to_query
    redirect_to u.to_s, allow_other_host: true
  end

  def callback
    if params[:state] != session.delete(:spotify_state)
      redirect_to(fallback_return_path, alert: "Stateが不正です") and return
    end

    res = Faraday.post("https://accounts.spotify.com/api/token") do |r|
      r.headers["Content-Type"] = "application/x-www-form-urlencoded"
      r.body = {
        grant_type:    "authorization_code",
        code:          params[:code],
        redirect_uri:  callback_uri,                       # ← startと同じ値を使う
        client_id:     ENV.fetch("SPOTIFY_CLIENT_ID"),
        client_secret: ENV.fetch("SPOTIFY_SECRET")
      }.to_query
    end

    unless res.success?
      redirect_to(fallback_return_path, alert: "Spotify連携エラー: #{res.status}") and return
    end

    b = JSON.parse(res.body)

    current_user.update!(
      spotify_access_token:      b["access_token"],
      spotify_refresh_token:     b["refresh_token"].presence || current_user.spotify_refresh_token,
      spotify_token_expires_at:  Time.current + b["expires_in"].to_i.seconds
    )

    redirect_to(session.delete(:return_to) || root_path, notice: "Spotify連携OK")
  rescue => e
    redirect_to(fallback_return_path, alert: "Spotify連携エラー: #{e.message}")
  end

  private

  # どちらかに統一：環境変数 or ルートヘルパ
  # ルートヘルパを使う場合は default_url_options[:host] を設定しておくこと
  def callback_uri
    ENV.fetch("SPOTIFY_REDIRECT_URI")
  end

  def fallback_return_path
    session.delete(:return_to) || root_path
  end
end
