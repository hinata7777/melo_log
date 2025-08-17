class UsersController < ApplicationController
  before_action :require_login, only: %i[edit update]
  before_action :set_user, only: %i[show edit update update_avatar]
  before_action :ensure_owner!, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      auto_login(@user)
      redirect_to root_path, notice: 'ユーザー登録が完了しました！'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ★ 公開マイページ
  def show
    # ページネーション（5件/ページ）
    @pagy, @posts = pagy(
      @user.posts.includes(:song).order(created_at: :desc),
      items: 5, 
      page: params[:page]
    )
    # 総投稿数＆最新投稿日時（ページングに依存しない）
    @posts_count    = @pagy.count
    @latest_post_at = @user.posts.maximum(:created_at)
  end

  def edit; end
  
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'ユーザー情報を更新しました！'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_avatar
    if params[:user]&.dig(:avatar_image).present?
      @user.avatar_image.attach(params[:user][:avatar_image])
      redirect_to edit_user_path(@user), notice: 'プロフィール画像を更新しました'
    elsif params[:remove] == '1' && @user.avatar_image.attached?
      @user.avatar_image.purge
      redirect_to edit_user_path(@user), notice: 'プロフィール画像を削除しました'
    else
      redirect_to edit_user_path(@user), alert: '画像ファイルを選択してください'
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # edit/update は本人のみ
  def ensure_owner!
    redirect_to root_path, alert: '権限がありません。' unless current_user == @user
  end

  def user_params
    params.require(:user).permit(:nickname, :avatar_image, :email, :password, :password_confirmation)
  end
end
