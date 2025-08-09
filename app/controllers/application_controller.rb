class ApplicationController < ActionController::Base
  private
  
  def not_authenticated
    redirect_to login_path, alert: 'ログインが必要です'
  end
end