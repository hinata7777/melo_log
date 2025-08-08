class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :ensure_owner!, only: :show

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

  def show
    @user = current_user
    @posts = @user.posts.order(created_at: :desc)
  end

  def edit
  @user = current_user
end

def update
  @user = current_user
  if @user.update(user_params)
    redirect_to @user, notice: 'プロフィールを更新しました！'
  else
    render :edit, status: :unprocessable_entity
  end
end

  private

  def user_params
    params.require(:user).permit(:nickname, :email, :password, :password_confirmation)
  end

  def ensure_owner!
    return if logged_in? && params[:id].to_s == current_user.id.to_s
    redirect_to user_path(current_user)
  end
end