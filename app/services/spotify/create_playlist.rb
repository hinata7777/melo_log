module Spotify
  class CreatePlaylist
    MAX_CHUNK = 100

    def initialize(access_token:, public: true)
      @token  = access_token
      @public = public
    end

    # return: 作成したプレイリストの Spotify URL
    def call(title:, description:, uris:)
      raise "曲がありません" if uris.blank?

      me   = get("https://api.spotify.com/v1/me")
      uid  = me["id"]

      pl = post("https://api.spotify.com/v1/users/#{uid}/playlists", {
        name: title, description: description, public: @public
      })
      pid = pl["id"]
      url = pl.dig("external_urls", "spotify")

      uris.each_slice(MAX_CHUNK) do |chunk|
        post("https://api.spotify.com/v1/playlists/#{pid}/tracks", { uris: chunk })
      end

      url
    end

    private

    def headers
      { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
    end

    def get(url)
      res = Faraday.get(url, nil, headers)
      raise "Spotify API error: #{res.status} #{res.body}" unless res.success?
      JSON.parse(res.body)
    end

    def post(url, payload)
      res = Faraday.post(url, payload.to_json, headers)
      raise "Spotify API error: #{res.status} #{res.body}" unless res.success?
      JSON.parse(res.body) rescue {}
    end
  end
end
