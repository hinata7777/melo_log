module Playlists
  class UpsertFromUser
    MIN_TRACKS = 15

    def initialize(user, limit: nil)
      @user, @limit = user, limit
    end

    def call
      posts = @user.posts.includes(:song).where.not(song_id: nil).order(created_at: :desc)
      posts = posts.limit(@limit) if @limit
      raise ArgumentError, "投稿が足りません（#{MIN_TRACKS}曲以上必要）" if posts.size < MIN_TRACKS

      slug  = "user-#{@user.id}-melolog"
      title = "#{@user.nickname.presence || 'ユーザー'}のMeloLog"

      upsert!(slug:, title:, generated_by: :user, posts:)
    end

    private

    def upsert!(slug:, title:, generated_by:, posts:)
      Playlist.transaction do
        pl = Playlist.lock.find_or_initialize_by(slug:)
        pl.update!(user: @user, title:, generated_by:, public: true)

        pl.playlist_items.delete_all
        now = Time.current
        bulk = posts.each_with_index.map { |p, i| { playlist_id: pl.id, post_id: p.id, position: i+1, created_at: now, updated_at: now } }
        PlaylistItem.insert_all!(bulk)
        pl
      end
    end
  end
end
