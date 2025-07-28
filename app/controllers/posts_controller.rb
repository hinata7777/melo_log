class PostsController < ApplicationController
  def new
    @post = Post.new
  end

  def create
    # 選択した曲が既存DBにあるか確認、なければ作成
    song = Song.find_or_create_by(spotify_id: params[:spotify_id]) do |s|
      s.title = params[:title]
      s.artist = params[:artist]
      s.album_art_url = params[:album_art_url]
      s.spotify_url = params[:spotify_url]
    end

    @post = Post.new(memory_text: params[:post][:memory_text], song: song)
    @post.user = current_user if defined?(current_user) && current_user

    if @post.save
      redirect_to @post, notice: "投稿が完了しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @post = Post.find(params[:id])
  end
end
