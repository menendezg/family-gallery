class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :photos, dependent: :nullify
  has_many :folders, dependent: :destroy

  normalizes :username, with: ->(u) { u.strip.downcase }
end
