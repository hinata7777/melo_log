require 'net/http'
require 'uri'
require 'json'
require 'base64'

class SpotifyService
  BASE_URL = "https://api.spotify.com/v1"

  # 曲検索
  def self.search(query)
    token = get_token
    url = URI("#{BASE_URL}/search?q=#{URI.encode_www_form_component(query)}&type=track&limit=5")

    response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(url)
      request['Authorization'] = "Bearer #{token}"
      http.request(request)
    end

    data = JSON.parse(response.body)
    tracks = data.dig("tracks", "items") || []

    tracks.map do |track|
      OpenStruct.new(
        spotify_id: track["id"],
        title: track["name"],
        artist: track["artists"].map { |a| a["name"] }.join(", "),
        album_art_url: track.dig("album", "images", 1, "url"),
        spotify_url: track["external_urls"]["spotify"]
      )
    end
  end

  # トークン取得
  def self.get_token
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
