class User < ApplicationRecord
  authenticates_with_sorcery!

  has_many :posts, dependent: :destroy

  # emailは前処理で正規化
  before_validation :downcase_email

  # メール
  validates :email,
            presence: true,
            length: { maximum: 255 },
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }

  # ニックネーム
  validates :nickname, presence: true, length: { maximum: 10 }

  # パスワード（新規 or 変更時のみ必須）
  with_options if: :password_required? do
    validates :password, presence: true, length: { minimum: 8 } # ←7より8推奨
    validates :password, confirmation: true
    validates :password_confirmation, presence: true
  end

  private

  def downcase_email
    self.email = email.to_s.strip.downcase
  end

  # Sorceryはpasswordが仮想属性に入るので、これで十分堅い
  def password_required?
    new_record? || password.present?
  end
end
