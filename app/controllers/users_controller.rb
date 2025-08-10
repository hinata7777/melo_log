class UsersController < ApplicationController
  before_action :require_login, only: %i[edit update]
  before_action :set_user, only: %i[show edit update]
  before_action :require_login, only: %i[edit update]
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
    @posts = @user.posts.includes(:song).order(created_at: :desc)
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'プロフィールを更新しました！'
    else
      render :edit, status: :unprocessable_entity
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
    params.require(:user).permit(:nickname, :email, :password, :password_confirmation)
  end
end
