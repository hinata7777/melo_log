class PostsController < ApplicationController
  skip_before_action :require_login, only: %i[new create show]

  def new
    @post = Post.new
  end
  
  def create
    # spotify_id があれば曲を作成/取得。なければ song=nil のまま → モデルのpresenceで弾く
    song = if params[:spotify_id].present?
      Song.find_or_create_by!(spotify_id: params[:spotify_id]) do |s|
        s.title         = params[:title]
        s.artist        = params[:artist]
        s.album_art_url = params[:album_art_url]
        s.spotify_url   = params[:spotify_url]
      end
    end

    # Post作成
    @post = Post.new(post_params.merge(song: song))
    @post.user = current_user if logged_in?

    if @post.save
      redirect_to @post, notice: "MeloLogを投稿しました！"
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @post ||= Post.new(post_params)
    e.record.errors.each { |attr, msg| @post.errors.add(attr, msg) }
    render :new, status: :unprocessable_entity
  end

  def show
    @post = Post.find(params[:id])
  end

  private

  def post_params
    params.require(:post).permit(:memory_text)
  end
end