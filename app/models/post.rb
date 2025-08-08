class Post < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :song, optional: true

  validates :song,        presence: { message: "を選択してください" }
  validates :memory_text, presence: { message: "を入力してください" }, length: { maximum: 300 }
end