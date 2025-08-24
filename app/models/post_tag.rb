class PostTag < ApplicationRecord
  belongs_to :post
  belongs_to :tag, counter_cache: true

  validate :resident_tag_requires_login

  private

  def resident_tag_requires_login
    return unless tag&.resident?
    # 投稿者がいない（未ログイン投稿）なら拒否
    if post&.user_id.blank?
      errors.add(:tag, "はログインユーザーのみ設定できます")
    end
  end
end
