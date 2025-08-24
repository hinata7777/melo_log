class PostsController < ApplicationController
  before_action :require_login, only: %i[edit update destroy]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_owner!, only: %i[edit update destroy]
  before_action :load_tags_for_form, only: %i[new edit]

  def new
    @post = Post.new
    load_tags_for_form
  end
  
  def create
    # spotify_id があれば曲を作成/取得。なければ song=nil のまま → モデルのpresenceで弾く
    song = 
      if params[:spotify_id].present?
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

    raw_ids = Array(params.dig(:post, :tag_ids)).reject(&:blank?)
    scope   = Tag.active.where(id: raw_ids)
    allowed_ids =
      if logged_in?
        raw_ids
      else
        Tag.where(id: raw_ids).where.not(category: :resident).pluck(:id)
      end
    @post.tag_ids = allowed_ids

    if @post.save
      redirect_to @post, notice: "MeloLogを投稿しました！"
    else
      load_tags_for_form
      flash.now[:alert] = @post.errors.full_messages.join("\n")
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @post ||= Post.new(post_params)
    e.record.errors.each { |attr, msg| @post.errors.add(attr, msg) }
    load_tags_for_form
    render :new, status: :unprocessable_entity
  end

  def show; end

  def edit; end

  def update
    if @post.update(post_params) # memory_text,tag のみ許可
      redirect_to user_path(@post.user, page: params[:page]),
                  notice: "投稿テキストを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    redirect_to user_path(current_user, page: params[:page]), notice: "投稿を削除しました"
  end

  private

  def post_params
    params.require(:post).permit(:memory_text, tag_ids: [])
  end

  def set_post
    @post = Post.includes(:tags, :song, :user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "この投稿は削除されています"
  end

  def authorize_owner!
    # 自分の投稿だけ削除可
    unless @post.user_id == current_user.id
      redirect_to user_path(current_user), alert: "権限がありません。"
    end
  end

  def load_tags_for_form
    if logged_in?
      @resident_tags = Tag.active.resident.order(:name)
    else
      @resident_tags = Tag.none # 表示しない/灰色表示用に使うなら .resident でもOK
    end
    @event_tags   = Tag.active.event.order(:name)
  end
end