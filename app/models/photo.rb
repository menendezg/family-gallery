class Photo < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :folder, optional: true

  has_one_attached :image

  validates :title, presence: true
  validates :image, presence: true
  validate :acceptable_image

  private

  MAGIC_BYTES = {
    "image/jpeg" => [ "\xFF\xD8\xFF" ],
    "image/png"  => [ "\x89PNG" ],
    "image/gif"  => [ "GIF87a", "GIF89a" ],
    "image/webp" => [ "RIFF" ]
  }.freeze

  def acceptable_image
    return unless image.attached?

    unless image.blob.byte_size <= 20.megabytes
      errors.add(:image, "is too large (max 20 MB)")
    end

    acceptable_types = MAGIC_BYTES.keys
    unless acceptable_types.include?(image.blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, GIF, or WebP")
      return
    end

    # Verify actual file content matches declared type
    image.blob.open do |file|
      header = file.read(12)
      signatures = MAGIC_BYTES[image.blob.content_type]
      unless signatures.any? { |sig| header.start_with?(sig) }
        errors.add(:image, "content does not match its file type")
      end
    end
  end
end
