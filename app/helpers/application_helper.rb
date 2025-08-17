module ApplicationHelper
  include Pagy::Frontend

  def avatar_src_for(user)
    user&.avatar_image&.attached? ? user.avatar_image : "avatars/default.png"
  end
end
