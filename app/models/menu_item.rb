class MenuItem < ApplicationRecord
  belongs_to :category
  has_many :best_sellers, dependent: :nullify
  has_many :daily_specials, dependent: :nullify
  has_many :booking_items, dependent: :destroy

  # Active Storage - cho phép nhiều ảnh
  has_many_attached :images

  # Enum cho unit
  enum unit: {
    'Phần' => 0,
    'Kg' => 1,
    'Lạng' => 2,
    'Nguyên Con' => 3
  }, _default: 'Phần'

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_defaults, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }

  # Helper method to get all image URLs (original size)
  def images_urls
    if images.attached?
      images.map { |img| rails_storage_proxy_url(img) }
    else
      []
    end
  end

  # Helper method to get optimized/resized images URLs for faster loading (800x600, optimized)
  def images_urls_medium
    if images.attached?
      images.map { |img| 
        begin
          variant_url(img, { resize_to_limit: [800, 600], format: :jpeg, saver: { quality: 85 } }) || rails_storage_proxy_url(img)
        rescue => e
          Rails.logger.error "Error in images_urls_medium for image #{img.id}: #{e.message}"
          rails_storage_proxy_url(img)
        end
      }
    else
      []
    end
  end

  # Helper method to get small thumbnail URLs (400x300, optimized for fast loading)
  def images_urls_thumb
    if images.attached?
      images.map { |img| 
        begin
          variant_url(img, { resize_to_limit: [400, 300], format: :jpeg, saver: { quality: 85 } }) || rails_storage_proxy_url(img)
        rescue => e
          Rails.logger.error "Error in images_urls_thumb for image #{img.id}: #{e.message}"
          rails_storage_proxy_url(img)
        end
      }
    else
      []
    end
  end

  # Lấy ảnh đầu tiên làm thumbnail (original)
  def thumbnail_url
    if images.attached?
      rails_storage_proxy_url(images.first)
    else
      image_url # fallback to old image_url field
    end
  end

  # Helper method to get optimized thumbnail URL (800x600)
  def thumbnail_url_medium
    if images.attached?
      begin
        variant_url(images.first, { resize_to_limit: [800, 600], format: :jpeg, saver: { quality: 85 } }) || thumbnail_url
      rescue => e
        Rails.logger.error "Error in thumbnail_url_medium: #{e.message}"
        thumbnail_url
      end
    else
      image_url
    end
  end

  # Helper method to get small thumbnail URL (400x300, optimized for fast loading)
  def thumbnail_url_thumb
    if images.attached?
      begin
        variant_url(images.first, { resize_to_limit: [400, 300], format: :jpeg, saver: { quality: 85 } }) || thumbnail_url
      rescue => e
        Rails.logger.error "Error in thumbnail_url_thumb: #{e.message}"
        thumbnail_url
      end
    else
      image_url
    end
  end

  def rails_storage_proxy_url(attachment)
    return nil unless attachment.present?
    host = ENV['APP_HOST'] || 'nhahangdavaong.com'
    Rails.application.routes.url_helpers.rails_storage_proxy_url(attachment, host: host, protocol: 'https')
  end

  def variant_url(attachment, transformations)
    return nil unless attachment.present?
    host = ENV['APP_HOST'] || 'nhahangdavaong.com'

    begin
      variant_options = transformations.dup
      variant = attachment.variant(variant_options)
      # Process variant synchronously to avoid HTTP/2 protocol errors
      processed_variant = variant.processed
      Rails.application.routes.url_helpers.rails_storage_proxy_url(processed_variant, host: host, protocol: 'https')
    rescue LoadError => e
      Rails.logger.error "Image processing library not available: #{e.message}"
      rails_storage_proxy_url(attachment)
    rescue ActiveStorage::FileNotFoundError, MiniMagick::Error, ImageProcessing::Error => e
      Rails.logger.error "Error processing variant: #{e.message}. Falling back to original."
      rails_storage_proxy_url(attachment)
    rescue => e
      Rails.logger.error "Error generating variant URL: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
      rails_storage_proxy_url(attachment)
    end
  end

  private

  def set_defaults
    self.active = true if active.nil?
    self.unit = 'Phần' if unit.nil?
    self.position ||= MenuItem.where(category_id: category_id).maximum(:position).to_i + 1
  end
end
