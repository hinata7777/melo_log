module ApplicationHelper
  include Pagy::Frontend

  # 添付があれば軽量variant、なければデフォ画像を返す
  def avatar_variant_for(user, size: 64, quality: 80, format: :jpg)
    return "avatars/default.png" unless user&.avatar_image&.attached?

    user.avatar_image.variant(
      resize_to_fill: [size, size],   # ちょうど size×size にトリミング＆リサイズ
      format: format,                 # PNGでもJPG/WebPに変換可（写真はjpg推奨）
      saver: { quality: quality }     # 圧縮率（80前後がバランス良い）
    )
  end
end
