class Song < ApplicationRecord
  has_many :posts, dependent: :destroy
end
