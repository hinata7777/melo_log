class ApplicationController < ActionController::Base
  include Pagy::Backend
  
  REQUIRED_SONGS = 15
  helper_method :required_songs
  def required_songs = REQUIRED_SONGS

  private
  
  def not_authenticated
    redirect_to login_path, alert: 'ログインが必要です'
  end
end