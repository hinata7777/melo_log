class PlaylistItem < ApplicationRecord
  belongs_to :playlist
  belongs_to :post
  validates :position, presence: true
end