class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  has_many :playlists, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  scope :active, -> { where(active: true) } 

  enum category: { resident: 0, event: 1 }
end
