class My::PlaylistsController < ApplicationController
  before_action :require_login

  def index
    @playlists = current_user.playlists.order(updated_at: :desc)
                             .includes(playlist_items: { post: [:song, :user] })
  end

  def create
    pl = Playlists::UpsertFromUser.new(current_user).call
    redirect_to playlist_path(pl.slug), notice: "マイプレイリストを作成/更新しました"
  rescue => e
    redirect_to my_playlists_path, alert: e.message
  end
end
