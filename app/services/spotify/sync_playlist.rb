module Spotify
  class SyncPlaylist
    MAX_CHUNK = 100

    def initialize(playlist, access_token:, public: true)
      @pl, @tok, @pub = playlist, access_token, public
    end

    def call
      uris = tracks_uris
      raise "曲がありません" if uris.empty?

      if @pl.spotify_playlist_id.present?
        update_details!
        replace_items!(uris)
      else
        uid = me_id!
        created = create_playlist!(uid, @pl.title, public: @pub, description: description_for(@pl))
        @pl.update!(spotify_playlist_id: created["id"], spotify_url: created.dig("external_urls","spotify"))
        replace_items!(uris)
      end
      @pl.spotify_url
    end

    private
    def headers = { "Authorization" => "Bearer #{@tok}", "Content-Type" => "application/json" }

    def me_id!
      JSON.parse(Faraday.get("https://api.spotify.com/v1/me", nil, headers).body).fetch("id")
    end

    def create_playlist!(user_id, name, public:, description:)
      body = { name:, public:, description: }.to_json
      JSON.parse(Faraday.post("https://api.spotify.com/v1/users/#{user_id}/playlists", body, headers).body)
    end

    def update_details!
      Faraday.put("https://api.spotify.com/v1/playlists/#{@pl.spotify_playlist_id}",
                  { name: @pl.title, public: @pub, description: description_for(@pl) }.to_json, headers)
    end

    def replace_items!(uris)
      first, rest = uris.first(MAX_CHUNK), uris.drop(MAX_CHUNK)
      Faraday.put("https://api.spotify.com/v1/playlists/#{@pl.spotify_playlist_id}/tracks", { uris: first }.to_json, headers)
      rest.each_slice(MAX_CHUNK) do |chunk|
        Faraday.post("https://api.spotify.com/v1/playlists/#{@pl.spotify_playlist_id}/tracks", { uris: chunk }.to_json, headers)
      end
    end

    def tracks_uris
      @pl.posts.includes(:song).where.not(song_id: nil).map { |p| "spotify:track:#{p.song.spotify_id}" }.uniq
    end

    # 省略可：説明文にMeloLogへの導線
    def description_for(pl)
      "Made with MeloLog — #{Rails.application.routes.url_helpers.playlist_url(pl.slug, host: ENV.fetch('APP_HOST', 'melolog.onrender.com'))}"
    end
  end
end
