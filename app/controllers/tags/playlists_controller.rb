class Tags::PlaylistsController < ApplicationController
  before_action :require_login

  def create
    tag = Tag.find_by!(slug: params[:tag_slug] || params[:slug])
    pl  = Playlists::UpsertFromTag.new(tag, creator_user: current_user).call
    redirect_to playlist_path(pl.slug), notice: "##{tag.name} のプレイリストを作成/更新しました"
  rescue => e
    redirect_to tag_path(tag.slug), alert: e.message
  end
end
