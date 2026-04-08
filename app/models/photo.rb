class Photo < ApplicationRecord
  belongs_to :user, optional: true

  has_one_attached :image

  validates :title, presence: true
  validates :image, presence: true
  validate :acceptable_image

  private

  def acceptable_image
    return unless image.attached?

    unless image.blob.byte_size <= 20.megabytes
      errors.add(:image, "is too large (max 20 MB)")
    end

    acceptable_types = [ "image/jpeg", "image/png", "image/gif", "image/webp" ]
    unless acceptable_types.include?(image.blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, GIF, or WebP")
    end
  end
end
