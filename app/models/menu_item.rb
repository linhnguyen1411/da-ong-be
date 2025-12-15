class MenuItem < ApplicationRecord
  belongs_to :category
  has_many :best_sellers, dependent: :nullify
  has_many :daily_specials, dependent: :nullify
  has_many :booking_items, dependent: :destroy

  # Active Storage - cho phép nhiều ảnh
  has_many_attached :images

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_defaults, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }

  # Helper method to get all image URLs
  def images_urls
    if images.attached?
      images.map { |img| Rails.application.routes.url_helpers.rails_blob_url(img, only_path: true) }
    else
      []
    end
  end

  # Lấy ảnh đầu tiên làm thumbnail
  def thumbnail_url
    if images.attached?
      Rails.application.routes.url_helpers.rails_blob_url(images.first, only_path: true)
    else
      image_url # fallback to old image_url field
    end
  end

  private

  def set_defaults
    self.active = true if active.nil?
    self.position ||= MenuItem.where(category_id: category_id).maximum(:position).to_i + 1
  end
end
