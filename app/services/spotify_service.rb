require "net/http"
require "uri"
require "json"
require "base64"
require "ostruct"
require "thread"  # Mutex

class SpotifyService
  BASE_URL  = "https://api.spotify.com/v1"
  TOKEN_URL = "https://accounts.spotify.com/api/token"

  def initialize
    # 検索用（Client Credentials）のキャッシュ
    @app_token = nil
    @app_token_expires_at = nil
    @token_mutex = Mutex.new
  end

  # ====== marketの単一決定点（ENV未設定でもJP固定） ======
  def market
    ENV.fetch("SPOTIFY_MARKET", "JP")
  end

  # ====== URI組み立て（market渡し忘れを物理的に防ぐ） ======
  def build_uri(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    q = URI.decode_www_form(uri.query.to_s) + params.to_a
    q << ["market", market] unless q.any? { |k, _| k.to_s == "market" }
    uri.query = URI.encode_www_form(q)
    uri
  end

  # ========== 検索：未ログインOK（Client Credentials） ==========
  # 初回から必ずJP寄りの結果になるように、アプリトークン＋market固定、401は自動リトライ
  def search(query, limit: 5, offset: 0, market: nil)
    market ||= self.market
    url = build_uri("/search", q: query, type: "track", limit: limit, offset: offset, market: market)

    # 日本からのアクセスに近づけるヘッダー
    headers = {
      "Accept-Language" => "ja-JP,ja;q=0.9,en-US;q=0.8,en;q=0.7",
      "X-Timezone" => "Asia/Tokyo",
      "Accept-Charset" => "UTF-8"
    }

    res = http_get_with_app_token(url, headers: headers)

    # サーバーの地理的位置を確認（デバッグ用）
    check_server_location if Rails.env.production?

    data  = safe_json(res.body)
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
    url = build_uri("/me/playlists") # marketは不要だがbuild_uriに統一
    res = http_post_json(url, { name: name, description: description, public: public },
                         bearer: developer_access_token!)
    return safe_json(res.body) if res.code.to_i == 201

    Rails.logger.error "Playlist creation failed: #{res.code} - #{res.body}"
    nil
  end

  def add_tracks_to_playlist(playlist_id, track_uris)
    url = build_uri("/playlists/#{playlist_id}/tracks")
    res = http_post_json(url, { uris: track_uris }, bearer: developer_access_token!)
    res.code.to_i == 201
  end

  # （必要なら）開発者アカの /me 情報
  def get_current_user
    url = build_uri("/me")
    res = http_get(url, bearer: developer_access_token!)
    return safe_json(res.body) if res.code.to_i == 200

    Rails.logger.error "User info fetch failed: #{res.code} - #{res.body}"
    nil
  end

  private

  # -------- Appトークン（Client Credentials）を取得・キャッシュ（同期） --------
  def app_token!
    @token_mutex.synchronize do
      if @app_token && @app_token_expires_at && Time.now < @app_token_expires_at
        return @app_token
      end

      client_id     = ENV.fetch("SPOTIFY_CLIENT_ID")
      client_secret = ENV.fetch("SPOTIFY_CLIENT_SECRET")
      basic = Base64.strict_encode64("#{client_id}:#{client_secret}")

      url = URI(TOKEN_URL)
      res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        with_timeout(http)
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

      # 期限切れ直前の401を避けるため、30秒マージン
      @app_token = token
      @app_token_expires_at = Time.now + [exp - 30, 0].max
      @app_token
    end
  end

  def reset_app_token!
    @token_mutex.synchronize do
      @app_token = nil
      @app_token_expires_at = nil
    end
  end

  # -------- 開発者アカのアクセストークン（ENV直読） --------
  # 後でrefresh_token方式に差し替え可
  def developer_access_token!
    ENV.fetch("SPOTIFY_DEV_ACCESS_TOKEN")
  end

  # -------- HTTP helpers --------
  # Appトークン専用：401（期限切れなど）は1回だけ再取得して自動リトライ
  def http_get_with_app_token(url, headers: {})
    res = http_get(url, bearer: app_token!, headers: headers)
    if res.code.to_i == 401
      Rails.logger.warn("[Spotify] 401 -> refresh token and retry for #{url}") rescue nil
      reset_app_token!
      res = http_get(url, bearer: app_token!, headers: headers)
    end
    res
  end

  # ★ Spotify主要GETへ行く直前に market=JP を強制付与し、送信URLをログ出力
  def http_get(url, bearer:, headers: {})
    url = ensure_market!(url)

    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      with_timeout(http)

      req = Net::HTTP::Get.new(url)
      req["Authorization"] = "Bearer #{bearer}"
      headers.each { |k, v| req[k] = v }
      res = http.request(req)

      # デバッグログ（安定後は削除OK） — トークン値は出さない
      begin
        market_q = URI.decode_www_form(url.query.to_s).assoc("market")&.last
        bearer_kind = (bearer == @app_token) ? "app" : "dev"
        Rails.logger.info("[Spotify] GET #{url} market=#{market_q} bearer=#{bearer_kind} status=#{res.code}")
      rescue => e
        Rails.logger.warn("[Spotify] log_error=#{e.class}: #{e.message}")
      end

      res
    end
  end

  def http_post_json(url, body_hash, bearer:)
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      with_timeout(http)
      req = Net::HTTP::Post.new(url)
      req["Authorization"] = "Bearer #{bearer}"
      req["Content-Type"]  = "application/json"
      req.body = body_hash.to_json
      res = http.request(req)
      begin
        Rails.logger.info("[Spotify] POST #{url} status=#{res.code}")
      rescue; end
      res
    end
  end

  # ---- ネットワーク安定化（タイムアウト） ----
  def with_timeout(http)
    http.open_timeout = 3
    http.read_timeout = 5
    http.write_timeout = 5 if http.respond_to?(:write_timeout)
  end

  # ---- Spotify主要エンドポイントなら必ず market を付ける（渡し忘れ防止の最終防波堤） ----
  def ensure_market!(uri)
    base_host = URI(BASE_URL).host rescue nil
    return uri unless base_host && uri.host == base_host

    need_paths = ["/v1/search", "/v1/tracks", "/v1/albums", "/v1/artists"]
    needs = need_paths.any? { |p| uri.path.start_with?(p) }
    return uri unless needs

    q = URI.decode_www_form(uri.query.to_s)
    unless q.any? { |k, _| k == "market" }
      q << ["market", market]
      new_uri = uri.dup
      new_uri.query = URI.encode_www_form(q)
      return new_uri
    end
    uri
  end

  def safe_json(str)
    JSON.parse(str)
  rescue
    {}
  end

  # サーバーの地理的位置をチェック（デバッグ用）
  def check_server_location
    begin
      response = Net::HTTP.get_response(URI('http://ipinfo.io/json'))
      if response.code == '200'
        location_data = JSON.parse(response.body)
        Rails.logger.info "[Server Location] IP: #{location_data['ip']}, Country: #{location_data['country']}, Region: #{location_data['region']}, City: #{location_data['city']}"
      end
    rescue => e
      Rails.logger.warn "[Server Location] Error: #{e.message}"
    end
  end
end
