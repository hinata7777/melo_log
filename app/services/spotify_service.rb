require 'net/http'
require 'uri'
require 'json'
require 'base64'

class SpotifyService
  BASE_URL = "https://api.spotify.com/v1"

  # 曲検索
  def search(query, limit: 5)
    token = get_token
    url = URI("#{BASE_URL}/search?q=#{URI.encode_www_form_component(query)}&type=track&limit=#{limit}&market=JP")

    response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(url)
      request['Authorization'] = "Bearer #{token}"
      request['Accept-Language'] = 'ja-JP,ja;q=0.9'
      http.request(request)
    end

    data = JSON.parse(response.body)
    search_tracks = data.dig("tracks", "items") || []

    # 検索結果から楽曲IDを取得
    track_ids = search_tracks.map { |track| track["id"] }.compact

    # /v1/tracks で詳細データを取得
    detailed_tracks = get_tracks_details(track_ids)

    # 詳細取得に成功した場合はそれを返し、失敗した場合は検索結果をフォールバック
    if detailed_tracks.any?
      detailed_tracks
    else
      # フォールバック：検索結果をそのまま使用
      search_tracks.map do |track|
        OpenStruct.new(
          spotify_id: track["id"],
          title: track["name"],
          artist: track["artists"].map { |a| a["name"] }.join(", "),
          album_art_url: track.dig("album", "images", 1, "url"),
          spotify_url: track["external_urls"]["spotify"]
        )
      end
    end
  end

  # 楽曲詳細取得（複数ID対応）
  def get_tracks_details(track_ids)
    return [] if track_ids.empty?

    token = get_token
    ids_string = track_ids.join(",")
    url = URI("#{BASE_URL}/tracks?ids=#{ids_string}&market=JP")

    response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(url)
      request['Authorization'] = "Bearer #{token}"
      request['Accept-Language'] = 'ja-JP,ja;q=0.9'
      http.request(request)
    end

    data = JSON.parse(response.body)
    tracks = data["tracks"] || []

    tracks.filter_map do |track|
      next if track.nil?

      OpenStruct.new(
        spotify_id: track["id"],
        title: track["name"],
        artist: track["artists"].map { |a| a["name"] }.join(", "),
        album_art_url: track.dig("album", "images", 1, "url"),
        spotify_url: track["external_urls"]["spotify"]
      )
    end
  rescue => e
    Rails.logger.error "[Spotify] get_tracks_details failed: #{e.message}" if defined?(Rails)
    []
  end

  private

  # トークン取得
  def get_token
    url = URI("https://accounts.spotify.com/api/token")
    auth = Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")

    response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(url)
      request['Authorization'] = "Basic #{auth}"
      request.set_form_data({ grant_type: 'client_credentials' })
      http.request(request)
    end

    JSON.parse(response.body)["access_token"]
  end
end