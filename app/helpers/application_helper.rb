module ApplicationHelper
  include Pagy::Frontend
  include CloudinaryHelper  # ← 追加（cl_image_path を使う）

  # Cloudinary配信用URLを返す。ビュー側は今まで通り image_tag(...) でOK
  def avatar_variant_for(user, size: 64)
    return image_path("avatars/default.png") unless user&.avatar_image&.attached?

    blob = user.avatar_image.blob

    # 旧:local 添付は原本が消えている可能性 → デフォにフォールバック
    current_service = Rails.application.config.active_storage.service.to_s
    if blob.service_name.to_s != current_service
      return image_path("avatars/default.png")
    end

    # Cloudinaryの公開IDは基本 blob.key
    # 変換は Cloudinary 側で実行（c_fill,w,h と f_auto/q_auto）
    cl_image_path(
      blob.key,
      width: size, height: size, crop: :fill,
      fetch_format: :auto, quality: :auto
    )
  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    # 原本がない壊れ添付は掃除してデフォに
    user.avatar_image.purge_later
    image_path("avatars/default.png")
  rescue => e
    Rails.logger.warn("avatar_variant_for fallback: #{e.class}: #{e.message}")
    image_path("avatars/default.png")
  end
end
