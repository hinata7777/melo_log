class Post < ApplicationRecord
  belongs_to :user
  belongs_to :song

  validates :memory_text, presence: true, length: { maximum: 300 }
  validates :song_id, presence: true
end