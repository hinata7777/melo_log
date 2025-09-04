class SpotifyPlaylistsController < ApplicationController
  # 「自分のプレイリストを作る」はログイン必須
  before_action :require_login_for_me!, only: :create_for_me

  # POST /me/playlist  （自分のマイページ向け：current_userの投稿を集計）
  def create_for_me
    user = current_user
    playlist = Playlist.find_or_initialize_by(user_id: user.id)
    if playlist.new_record?
      playlist.title = "#{user.nickname} の MeloLog"
      playlist.slug  = "user-#{user.id}" # 既存スキーマ：slug は必須＆一意
      playlist.save!
    end

    url = Spotify::SyncPlaylist.new(playlist).call
    redirect_to url, allow_other_host: true
  rescue => e
    redirect_back fallback_location: user_path(user), alert: "プレイリスト作成に失敗: #{e.message}"
  end

  # POST /users/:id/playlist  （他人のマイページからでも、その人の投稿を集計）
  def create_for_user
    user = User.find(params[:id])  # ← ページ所有者
    playlist = Playlist.find_or_initialize_by(user_id: user.id)
    if playlist.new_record?
      playlist.title = "#{user.nickname} の MeloLog"
      playlist.slug  = "user-#{user.id}"
      playlist.save!
    end

    url = Spotify::SyncPlaylist.new(playlist).call
    redirect_to url, allow_other_host: true
  rescue => e
    redirect_back fallback_location: user_path(user), alert: "プレイリスト作成に失敗: #{e.message}"
  end

  # POST /tags/:id/playlist  （タグページ向け：そのタグの投稿を集計）
  def create_for_tag
    tag = Tag.find(params[:id])
    playlist = Playlist.find_or_initialize_by(tag_id: tag.id)
    if playlist.new_record?
      playlist.title = "#{tag.name} の MeloLog"
      playlist.slug  = "tag-#{tag.id}"
      playlist.save!
    end

    url = Spotify::SyncPlaylist.new(playlist).call
    redirect_to url, allow_other_host: true
  rescue => e
    redirect_back fallback_location: tag_path(tag), alert: "プレイリスト作成に失敗: #{e.message}"
  end

  private

  def require_login_for_me!
    unless respond_to?(:logged_in?) && logged_in? && current_user
      redirect_to login_path, alert: "ログインが必要です"
    end
  end
end
