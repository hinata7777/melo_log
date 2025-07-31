class PostsController < ApplicationController
  def new
    @post = Post.new
  end
  
  def create
    # 1. 送られてきた曲情報を取得
    spotify_id = params[:spotify_id]
    title = params[:title]
    artist = params[:artist]
    album_art_url = params[:album_art_url]
    spotify_url = params[:spotify_url]

    # 2. 既存のSongがあるかチェック、なければ作成
    song = Song.find_or_create_by(spotify_id: spotify_id) do |s|
      s.title = title
      s.artist = artist
      s.album_art_url = album_art_url
      s.spotify_url = spotify_url
    end

    # 3. Postを作成（ログイン後なら current_user.id に差し替え）
    @post = Post.new(
      user_id: 1, # ログイン機能つけたら current_user.id に変更
      song_id: song.id,
      memory_text: params[:post][:memory_text]
    )

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
