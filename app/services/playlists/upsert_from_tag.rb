module Playlists
  class UpsertFromTag
    MIN_TRACKS = 10

    def initialize(tag, creator_user: nil, limit: nil)
      @tag, @creator, @limit = tag, creator_user, limit
    end

    def call
      posts = @tag.posts.includes(:song, :user).where.not(song_id: nil).order(created_at: :desc)

      seen = {}
      posts = posts.select { |p| next false if seen[p.song_id]; seen[p.song_id] = true }
      posts = posts.first(@limit) if @limit
      raise ArgumentError, "このタグの投稿が足りません（#{MIN_TRACKS}曲以上必要）" if posts.size < MIN_TRACKS

      slug  = "tag-#{@tag.slug}-melolog"
      title = "【##{@tag.name}】MeloLogプレイリスト"

      upsert!(slug:, title:, generated_by: :tag, posts:)
    end

    private

    def upsert!(slug:, title:, generated_by:, posts:)
      Playlist.transaction do
        pl = Playlist.lock.find_or_initialize_by(slug:)
        pl.update!(tag: @tag, user: @creator, title:, generated_by:, public: true)

        pl.playlist_items.delete_all
        now = Time.current
        bulk = posts.each_with_index.map { |p, i| { playlist_id: pl.id, post_id: p.id, position: i+1, created_at: now, updated_at: now } }
        PlaylistItem.insert_all!(bulk)
        pl
      end
    end
  end
end
