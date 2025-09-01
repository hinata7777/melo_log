class Admin::PostsController < Admin::BaseController
  def index
    @q = params[:q].to_s.strip
    scope = Post.includes(:song, :user).order(created_at: :desc)
    scope = scope.where(user_id: nil) if params[:only_anonymous] == "1"

    if @q.present?
      scope = scope.joins(:song).left_joins(:user)
                   .where(
                     "songs.title ILIKE :q OR songs.artist ILIKE :q OR posts.memory_text ILIKE :q OR users.email ILIKE :q",
                     q: "%#{@q}%"
                   )
    end

    @pagy, @posts = pagy(scope)
  end

  def destroy
    post = Post.find(params[:id])
    post.destroy! # 関連も含めコールバック実行
    redirect_back fallback_location: admin_posts_path, notice: "投稿 ##{post.id} を削除しました"
  end
end
