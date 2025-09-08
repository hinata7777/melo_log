module ApplicationHelper
  include Pagy::Frontend

  # 添付があれば Cloudinary で最適化したバリアント、なければデフォ画像を返す
  def avatar_variant_for(user, size: 64)
    return "avatars/default.png" unless user&.avatar_image&.attached?

    user.avatar_image.variant(
      resize_to_fill: [size, size], # c_fill,w_{size},h_{size}
      quality: "auto",              # q_auto
      fetch_format: "auto"          # f_auto（WebP/AVIFなど最適化）
    ).processed
  end
end
