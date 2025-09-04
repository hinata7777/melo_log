require "base64"
require "json"
require "uri"

class Admin::SpotifyBotController < ApplicationController
  before_action :require_admin!
  before_action :allow_only_when_enabled!

  AUTH_URL  = "https://accounts.spotify.com/authorize"
  TOKEN_URL = "https://accounts.spotify.com/api/token"
  SCOPES    = %w[playlist-modify-public playlist-modify-private].join(" ")

  def connect
    state = SecureRandom.hex(16)
    session[:spotify_state] = state
    q = {
      client_id:     ENV.fetch("SPOTIFY_CLIENT_ID"),
      response_type: "code",
      redirect_uri:  ENV.fetch("SPOTIFY_REDIRECT_URI"),
      scope:         SCOPES,
      state:         state,
      show_dialog:   true
    }
    redirect_to "#{AUTH_URL}?#{q.to_query}", allow_other_host: true
  end

  def callback
    raise "state mismatch" if params[:state] != session.delete(:spotify_state)

    code_param = params[:code].to_s
    form = {
      grant_type:   "authorization_code",
      code:         code_param,
      redirect_uri: ENV.fetch("SPOTIFY_REDIRECT_URI")
    }
    headers = {
      "Authorization" => "Basic " + Base64.strict_encode64("#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}"),
      "Content-Type"  => "application/x-www-form-urlencoded"
    }

    res   = Faraday.post(TOKEN_URL, URI.encode_www_form(form), headers)
    body  = JSON.parse(res.body) rescue {}
    refresh = body["refresh_token"]
    raise "no refresh_token returned (status=#{res.status})" unless refresh

    render plain: <<~TEXT
      取得成功！
      下の値を .env または Render の SPOTIFY_BOT_REFRESH_TOKEN に設定して、再起動/再デプロイしてください。

      SPOTIFY_BOT_REFRESH_TOKEN=#{refresh}

      ※設定し終えたら、このルートは必ず無効化/削除してください。
    TEXT
  end

  private

  def require_admin!
    # あなたのアプリに admin 判定があるならそれを使ってください
    # 仮置き：常に許可（開発用）
    true
  end

  def allow_only_when_enabled!
    head :forbidden unless ENV["ALLOW_BOT_CONNECT"] == "1"
  end
end
