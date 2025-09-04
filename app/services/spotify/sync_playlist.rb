require "digest"

module Spotify
  class SyncPlaylist
    def initialize(playlist)
      @pl = playlist
    end

    # プレイリストURLを返す
    def call
      uris = collect_uris_for(@pl)
      raise "曲がありません" if uris.empty?

      token  = BotToken.fetch_access_token!
      client = Client.new(token)
      owner  = client.me  # ← Bot(MeloLog) アカウント

      title = @pl.title.presence || default_title(@pl)
      desc  = description_for(@pl)

      if @pl.spotify_playlist_id.present?
        # 既存プレイリストの情報更新＆トラック全置換
        client.update_details!(playlist_id: @pl.spotify_playlist_id, name: title, description: desc, public: public?)
        client.replace_items!(playlist_id: @pl.spotify_playlist_id, uris: uris)
        url = @pl.spotify_url.presence || "https://open.spotify.com/playlist/#{@pl.spotify_playlist_id}"
      else
        # 新規作成 → 曲を追加
        created = client.create_playlist!(user_id: owner["id"], name: title, description: desc, public: public?)
        client.add_items!(playlist_id: created["id"], uris: uris)
        @pl.spotify_playlist_id = created["id"]
        url = created.dig("external_urls", "spotify")
      end

      @pl.update!(title: title, spotify_url: url)
      url
    end

    private

    def public?
      @pl.respond_to?(:public) ? @pl.public : true
    end

    def collect_uris_for(pl)
      # 既存スキーマに合わせて、user_id があればユーザー向け、なければ tag_id を使う
      posts =
        if pl.user_id.present?
          Post.where(user_id: pl.user_id).includes(:song).order(:created_at)
        elsif pl.tag_id.present?
          Post.joins(:post_tags).where(post_tags: { tag_id: pl.tag_id }).includes(:song).order(:created_at)
        else
          raise "playlist には user_id または tag_id のどちらかが必要です"
        end

      posts.filter_map { |p|
        s = p.song
        next nil unless s
        if s.respond_to?(:spotify_uri) && s.spotify_uri.present?
          s.spotify_uri
        elsif s.respond_to?(:spotify_id) && s.spotify_id.present?
          "spotify:track:#{s.spotify_id}"
        else
          nil
        end
      }.uniq
    end

    def default_title(pl)
      if pl.user_id.present?
        "#{pl.user&.nickname || pl.user&.id} の MeloLog"
      elsif pl.tag_id.present?
        "##{pl.tag&.name} の MeloLog"
      end
    end

    def description_for(pl)
      if pl.user_id.present?
        "MeloLog公式による #{pl.user&.nickname || pl.user&.id} さんの投稿曲まとめプレイリスト"
      elsif pl.tag_id.present?
        "MeloLog公式による ##{pl.tag&.name} の投稿曲まとめプレイリスト"
      end
    end
  end
end
