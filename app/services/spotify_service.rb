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
    @app_token = nil
    @app_token_expires_at = nil
  end

  def search(query, limit: 5)
    token = app_token!

    # より確実にmarketパラメータを送信
    url = URI("#{BASE_URL}/search")
    url.query = URI.encode_www_form(
      q: query.to_s,
      type: "track",
      limit: limit.to_i,
      market: "JP"
    )

    accept_lang = "ja"

    res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(url)
      req["Authorization"]   = "Bearer #{token}"
      req["Accept-Language"] = accept_lang
      http.request(req)
    end

    data  = safe_json(res.body)

    # 開発環境と本番環境の違いを確認するためのログ
    Rails.logger.info "=== Spotify API Debug ==="
    Rails.logger.info "Environment: #{Rails.env}"
    Rails.logger.info "Request URL: #{url}"
    Rails.logger.info "Request Headers: Authorization=Bearer [token], Accept-Language=#{accept_lang}"
    Rails.logger.info "Response Status: #{res.code}"
    if data.dig("tracks", "items")&.first
      first_track = data.dig("tracks", "items").first
      Rails.logger.info "First Track: #{first_track['name']} by #{first_track.dig('artists', 0, 'name')}"
    end
    Rails.logger.info "========================="

    items = data.dig("tracks", "items") || []

    items.map do |t|
      OpenStruct.new(
        spotify_id:    t["id"],
        title:         t["name"],
        artist:        (t["artists"] || []).map { _1["name"] }.join(", "),
        album_art_url: t.dig("album", "images", 1, "url") || t.dig("album", "images", 0, "url"),
        spotify_url:   t.dig("external_urls", "spotify"),
        uri:           t["uri"]
      )
    end
  end

  private

  # Client Credentials の簡易キャッシュ
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
      req.set_form_data({ grant_type: "client_credentials" })
      http.request(req)
    end

    body  = safe_json(res.body)
    token = body["access_token"].to_s
    exp   = body["expires_in"].to_i
    raise "Spotify app token fetch failed: #{res.code} - #{res.body}" if token.empty?

    @app_token = token
    # 期限直前の401を避けるため 30秒マージン
    @app_token_expires_at = Time.now + [exp - 30, 0].max
    @app_token
  end

  def safe_json(str)
    JSON.parse(str)
  rescue
    {}
  end
end
