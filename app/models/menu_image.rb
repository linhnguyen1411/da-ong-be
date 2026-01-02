class MenuImage < ApplicationRecord
  # Active Storage - một ảnh menu
  has_one_attached :image

  validates :position, presence: true
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }

  # Helper method to get image URL
  def image_url
    if image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true)
    else
      nil
    end
  end
end
