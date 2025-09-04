require "base64"
require "json"
require "uri"

module Spotify
  class BotToken
    TOKEN_URL = "https://accounts.spotify.com/api/token"

    # Botのrefresh_token から access_token を発行
    def self.fetch_access_token!
      refresh_token = ENV["SPOTIFY_BOT_REFRESH_TOKEN"] or raise "Missing SPOTIFY_BOT_REFRESH_TOKEN"
      client_id     = ENV.fetch("SPOTIFY_CLIENT_ID")
      client_secret = ENV.fetch("SPOTIFY_CLIENT_SECRET")

      form = { grant_type: "refresh_token", refresh_token: refresh_token }
      headers = {
        "Authorization" => "Basic " + Base64.strict_encode64("#{client_id}:#{client_secret}"),
        "Content-Type"  => "application/x-www-form-urlencoded"
      }

      res = Faraday.post(TOKEN_URL, URI.encode_www_form(form), headers)
      body = JSON.parse(res.body) rescue {}
      token = body["access_token"] or raise "failed to fetch access_token (status=#{res.status})"
      token
    end
  end
end
