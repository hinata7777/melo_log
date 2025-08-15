# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
  # 非ログイン時でも使える想定なら認可フィルタは不要

  def new ;end

  def create
    # メールアドレスは小文字で扱う派
    email = params[:email].to_s.strip.downcase
    user  = User.find_by(email: email)

    # ユーザーがいたら送る（いなくても同じフラッシュで返す）
    user&.deliver_reset_password_instructions!

    redirect_to root_path, notice: "パスワードリセット用のメールを送信しました"
  end

  def edit
    @token = params[:token]
    @user  = User.load_from_reset_password_token(@token)
    return redirect_to(new_password_reset_path, alert: "トークンが無効または期限切れです。") if @user.blank?
  end

  def update
    token = params[:token]
    @user = User.load_from_reset_password_token(token)
    return redirect_to(new_password_reset_path, alert: "トークンが無効または期限切れです。") if @user.blank?

    new_password = params.dig(:user, :password)
    confirmation  = params.dig(:user, :password_confirmation)

    # 先に確認用をセットしておく（あなたのUserモデルは confirmation: true バリデあり）
    @user.password_confirmation = confirmation

    # Sorceryは引数1つだけ（新しいパスワード）
    if @user.change_password!(new_password)
      redirect_to login_path, notice: "パスワードを変更しました。ログインしてください。"
    else
      @token = token
      flash.now[:alert] = "パスワードを更新できません。入力を見直してください。"
      render :edit, status: :unprocessable_entity
    end
  end
end
