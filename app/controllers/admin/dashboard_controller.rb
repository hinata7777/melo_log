class Admin::DashboardController < Admin::BaseController
  def index
    @users_last7 = User.where("created_at >= ?", 7.days.ago).count
    @posts_last7 = Post.where("created_at >= ?", 7.days.ago).count
  end
end