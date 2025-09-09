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

  # 日本向け固定（ENVで上書き可）
  def market
    ENV["SPOTIFY_MARKET"] || "JP"
  end

  # --- 検索：常に日本語優先ヘッダ＋market=JP、5件のみ ---
  def search(query, limit: 5)
    token = app_token!

    url = URI("#{BASE_URL}/search")
    url.query = URI.encode_www_form(
      q:     query,
      type:  "track",
      limit: limit,
      market: market
    )

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
    token = body["access_token"]
    exp   = body["expires_in"].to_i
    raise "Spotify app token fetch failed: #{res.code} - #{res.body}" if token.to_s.empty?

    @app_token = token
    @app_token_expires_at = Time.now + exp
    @app_token
  end

  def safe_json(str)
    JSON.parse(str)
  rescue
    {}
  end
end
