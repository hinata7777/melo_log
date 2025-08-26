class Playlist < ApplicationRecord
  enum generated_by: { user: 0, tag: 1, admin: 2 }

  belongs_to :user, optional: true
  belongs_to :tag,  optional: true

  has_many :playlist_items, -> { order(:position) }, dependent: :destroy
  has_many :posts, through: :playlist_items

  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: true

  before_validation :ensure_slug
  
  private
  
  def ensure_slug
    self.slug ||= "#{title.to_s.parameterize}-#{SecureRandom.hex(3)}"
  end
end