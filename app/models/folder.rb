class Folder < ApplicationRecord
  belongs_to :user, optional: true
  has_many :photos, dependent: :nullify

  validates :name, presence: true
end
