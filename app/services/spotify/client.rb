require "json"
require "uri"

module Spotify
  class Client
    BASE = "https://api.spotify.com/v1"

    def initialize(access_token)
      @headers = {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type"  => "application/json"
      }
    end

    def me
      jget("/me")
    end

    def create_playlist!(user_id:, name:, description:, public: true)
      jpost("/users/#{user_id}/playlists", {
        name: name, description: description, public: public
      })
    end

    def update_details!(playlist_id:, name:, description:, public: true)
      # 更新時は public を送らない（送ると 400 が出るケースがある）
      body = { name: name, description: description }
      jput("/playlists/#{playlist_id}", body)
    end

    def replace_items!(playlist_id:, uris:)
      jput("/playlists/#{playlist_id}/tracks", { uris: uris })
    end

    def add_items!(playlist_id:, uris:)
      uris.each_slice(100) do |chunk|
        jpost("/playlists/#{playlist_id}/tracks", { uris: chunk })
      end
    end

    private

    def jget(path, params=nil)
      res = Faraday.get(BASE + path, params, @headers)
      parse_json(res)
    end

    def jpost(path, body)
      res = Faraday.post(BASE + path, body.to_json, @headers)
      parse_json(res)
    end

    def jput(path, body)
      res = Faraday.put(BASE + path, body.to_json, @headers)
      # 空ボディの場合は空ハッシュ
      return {} if res.body.to_s.strip.empty?
      parse_json(res)
    end

    def parse_json(res)
      body = res.body.to_s
      ct   = res.headers["content-type"].to_s

      # 正常JSONの判定（Content-Type か 先頭文字で判定）
      if ct.include?("application/json") || body.lstrip.start_with?("{", "[")
        json = JSON.parse(body)
        # Spotifyのエラー形式もJSONなので、それはそれで例外にして見やすくする
        if json.is_a?(Hash) && json["error"].is_a?(Hash)
          code = json["error"]["status"] || json["error"]["code"]
          msg  = json["error"]["message"] || json["error_description"]
          raise "Spotify API error (status=#{res.status}, code=#{code}): #{msg}"
        end
        return json
      end

      # JSON以外が返った場合は、ステータスと先頭の断片を出して原因を特定しやすくする
      snippet = body[0, 160].gsub(/\s+/, " ")
      raise "Spotify API non-JSON (status=#{res.status}, content-type=#{ct}): #{snippet}"
    end
  end
end