class BestSeller < ApplicationRecord
  belongs_to :menu_item, optional: true

  # Active Storage - multiple images
  has_many_attached :images

  before_validation :set_defaults, on: :create

  scope :active, -> { where(active: true) }
  scope :pinned, -> { where(pinned: true) }
  scope :highlighted, -> { where(highlighted: true) }
  scope :ordered, -> { order(pinned: :desc, position: :asc) }

  # Helper method to get images URLs
  def images_urls
    if images.attached?
      images.map { |img| Rails.application.routes.url_helpers.rails_blob_url(img, only_path: true) }
    else
      []
    end
  end

  # Helper method to get thumbnail URL
  def thumbnail_url
    if images.attached?
      Rails.application.routes.url_helpers.rails_blob_url(images.first, only_path: true)
    elsif menu_item&.images&.attached?
      Rails.application.routes.url_helpers.rails_blob_url(menu_item.images.first, only_path: true)
    end
  end

  private

  def set_defaults
    self.active = true if active.nil?
    self.pinned = false if pinned.nil?
    self.highlighted = false if highlighted.nil?
    self.position ||= BestSeller.maximum(:position).to_i + 1
  end
end
