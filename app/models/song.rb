class Song < ApplicationRecord
  has_many :posts, dependent: :restrict_with_exception

  validates :spotify_id, presence: true, uniqueness: true
  validates :title,      presence: true
  validates :artist,     presence: true

  # URL系は来れば形式チェック、空ならスルー
  VALID_URL = %r{\Ahttps?://}i
  validates :album_art_url, format: { with: VALID_URL }, allow_blank: true
  validates :spotify_url,   format: { with: VALID_URL }, allow_blank: true
end
