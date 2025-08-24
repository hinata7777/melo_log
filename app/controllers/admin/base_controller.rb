class Admin::BaseController < ApplicationController
  before_action :require_login
  before_action :require_admin!

  private

  def require_admin!
    redirect_to root_path, alert: "権限がありません" unless current_user&.admin?
  end
end