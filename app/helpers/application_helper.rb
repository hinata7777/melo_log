module ApplicationHelper
  include Pagy::Frontend

  def avatar_variant_for(user, size: 64)
    return "avatars/default.png" unless user&.avatar_image&.attached?

    # 旧:local の添付は今の :cloudinary とサービス名が違うので即フォールバック
    current_service = Rails.application.config.active_storage.service.to_s
    blob_service    = user.avatar_image.blob.service_name
    return "avatars/default.png" if blob_service.present? && blob_service != current_service

    user.avatar_image.variant(
      resize_to_fill: [size, size],
      quality: "auto",
      fetch_format: "auto"
    ).processed
  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    # 原本がもう無い（Renderのエフェメラルで消えた）→ 落とさずフォールバック
    user.avatar_image.purge_later
    "avatars/default.png"
  end
end
