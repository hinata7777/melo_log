Rails.application.config.sorcery.submodules = [
  :reset_password
]

Rails.application.config.sorcery.configure do |config|  
  config.user_config do |user|
    user.reset_password_mailer = UserMailer
    user.reset_password_email_method_name = :reset_password_email
    
    user.reset_password_expiration_period = 2.hours
    user.stretches = 1 if Rails.env.test?
  end

  config.user_class = "User"
end
