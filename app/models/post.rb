class Post < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :song, optional: true

  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  has_many :playlist_items, dependent: :destroy
  has_many :playlists, through: :playlist_items
  
  validates :song,        presence: { message: "を選択してください" }
  validates :memory_text, presence: { message: "を入力してください" }, length: { maximum: 300 }
end