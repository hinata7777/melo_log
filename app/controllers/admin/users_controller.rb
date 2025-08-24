class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[show update]

  def index
    @q = params[:q].to_s.strip
    @users = User.order(created_at: :desc)
    @users = @users.where("nickname ILIKE ? OR email ILIKE ?", "%#{@q}%", "%#{@q}%") if @q.present?
  end

  def show; end

  def update
    # 役割の更新（最後の管理者を一般に落とすのは阻止）
    if params[:user]&.key?(:role)
      new_role = params[:user][:role]
      if last_admin_being_demoted?(@user, new_role)
        redirect_to admin_user_path(@user), alert: "最後の管理者は一般に変更できません" and return
      end
      @user.update!(role: new_role)
      redirect_to admin_user_path(@user), notice: "権限を更新しました"
    else
      redirect_to admin_user_path(@user), alert: "更新内容がありません"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def last_admin_being_demoted?(user, new_role)
    user.admin? && new_role.to_s == "general" && User.where(role: :admin).where.not(id: user.id).none?
  end
end