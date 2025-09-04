# app/services/spotify_service.rb
require "net/http"
require "uri"
require "json"
require "base64"
require "ostruct"

class SpotifyService
  BASE_URL  = "https://api.spotify.com/v1"
  TOKEN_URL = "https://accounts.spotify.com/api/token"

  def initialize
    # 検索用（Client Credentials）の簡易キャッシュ
    @app_token = nil
    @app_token_expires_at = nil
  end

  # ========== 検索：未ログインOK（Client Credentials） ==========
  def search(query, limit: 5, market: "JP")
    token = app_token!

    url = URI("#{BASE_URL}/search?q=#{URI.encode_www_form_component(query)}&type=track&limit=#{limit}&market=#{market}")
    res = http_get(url, bearer: token, headers: { "Accept-Language" => "ja-JP,ja;q=0.9" })
    data = safe_json(res.body)
    items = data.dig("tracks", "items") || []

    items.map do |t|
      OpenStruct.new(
        spotify_id:     t["id"],
        title:          t["name"],
        artist:         (t["artists"] || []).map { _1["name"] }.join(", "),
        album_art_url:  t.dig("album", "images", 1, "url") || t.dig("album", "images", 0, "url"),
        spotify_url:    t.dig("external_urls", "spotify"),
        uri:            t["uri"]
      )
    end
  end

  # ========== プレイリスト系：常に“開発者アカ”に作成 ==========
  def create_playlist(name, description = "", public: true)
    url = URI("#{BASE_URL}/me/playlists")
    res = http_post_json(url, { name: name, description: description, public: public },
                         bearer: developer_access_token!)
    return safe_json(res.body) if res.code.to_i == 201

    Rails.logger.error "Playlist creation failed: #{res.code} - #{res.body}"
    nil
  end

  def add_tracks_to_playlist(playlist_id, track_uris)
    url = URI("#{BASE_URL}/playlists/#{playlist_id}/tracks")
    res = http_post_json(url, { uris: track_uris }, bearer: developer_access_token!)
    res.code.to_i == 201
  end

  # （必要なら）開発者アカの /me 情報
  def get_current_user
    url = URI("#{BASE_URL}/me")
    res = http_get(url, bearer: developer_access_token!)
    return safe_json(res.body) if res.code.to_i == 200

    Rails.logger.error "User info fetch failed: #{res.code} - #{res.body}"
    nil
  end

  private

  # -------- Appトークン（Client Credentials）を取得・キャッシュ --------
  def app_token!
    if @app_token && @app_token_expires_at && Time.now < @app_token_expires_at
      return @app_token
    end

    client_id     = ENV.fetch("SPOTIFY_CLIENT_ID")
    client_secret = ENV.fetch("SPOTIFY_CLIENT_SECRET")
    basic = Base64.strict_encode64("#{client_id}:#{client_secret}")

    url = URI(TOKEN_URL)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(url)
      req["Authorization"] = "Basic #{basic}"
      req["Content-Type"]  = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form(grant_type: "client_credentials")
      http.request(req)
    end

    body = safe_json(res.body)
    token = body["access_token"]
    exp   = body["expires_in"].to_i
    raise "Spotify app token fetch failed: #{res.code} - #{res.body}" if token.nil?

    @app_token = token
    @app_token_expires_at = Time.now + exp
    @app_token
  end

  # -------- 開発者アカのアクセストークン（遅延取得） --------
  # ※まずは環境変数から読む方式。後でrefresh_token方式に差し替え可能。
  def developer_access_token!
    ENV.fetch("SPOTIFY_DEV_ACCESS_TOKEN")
  end

  # -------- HTTP helpers --------
  def http_get(url, bearer:, headers: {})
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(url)
      req["Authorization"] = "Bearer #{bearer}"
      headers.each { |k, v| req[k] = v }
      http.request(req)
    end
  end

  def http_post_json(url, body_hash, bearer:)
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(url)
      req["Authorization"] = "Bearer #{bearer}"
      req["Content-Type"]  = "application/json"
      req.body = body_hash.to_json
      http.request(req)
    end
  end

  def safe_json(str)
    JSON.parse(str) rescue {}
  end
end
