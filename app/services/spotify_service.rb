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

    encoded_q = URI.encode_www_form_component(query.to_s)
    url = URI("#{BASE_URL}/search?q=#{encoded_q}&type=track&limit=#{limit.to_i}&market=JP")

    res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(url)
      req["Authorization"]   = "Bearer #{token}"
      req["Accept-Language"] = "ja-JP,ja;q=0.9"
      http.request(req)
    end

    data  = safe_json(res.body)
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
      req["Content-Type"]  = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form(grant_type: "client_credentials")
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
