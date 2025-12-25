class Room < ApplicationRecord
  has_many :room_images, dependent: :destroy
  has_many :bookings, dependent: :destroy

  # Active Storage - multiple images
  has_many_attached :images

  validates :name, presence: true, uniqueness: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[available occupied maintenance] }

  before_validation :set_defaults, on: :create
  before_save :handle_position_change, if: :will_save_change_to_position?
  after_destroy :reorder_all_positions

  scope :active, -> { where(active: true) }
  scope :available, -> { where(status: 'available') }
  scope :ordered, -> { order(position: :asc) }

  accepts_nested_attributes_for :room_images, allow_destroy: true

  def available?
    status == 'available'
  end

  def occupied?
    status == 'occupied'
  end

  # Helper method to get images URLs (original size)
  def images_urls
    if images.attached?
      images.map { |img| rails_storage_proxy_url(img) }
    else
      room_images.map(&:image_url)
    end
  end

  # Helper method to get optimized/resized images URLs for faster loading
  def images_urls_medium
    if images.attached?
      images.map { |img| 
        begin
          variant_url(img, resize_to_limit: [800, 600]) || rails_storage_proxy_url(img)
        rescue => e
          Rails.logger.error "Error in images_urls_medium for image #{img.id}: #{e.message}"
          rails_storage_proxy_url(img)
        end
      }
    else
      room_images.map(&:image_url)
    end
  end

  # Helper method to get small thumbnail URLs
  def images_urls_thumb
    if images.attached?
      images.map { |img| 
        begin
          variant_url(img, resize_to_limit: [400, 300]) || rails_storage_proxy_url(img)
        rescue => e
          Rails.logger.error "Error in images_urls_thumb for image #{img.id}: #{e.message}"
          rails_storage_proxy_url(img)
        end
      }
    else
      room_images.map(&:image_url)
    end
  end

  # Helper method to get thumbnail URL (original)
  def thumbnail_url
    if images.attached?
      rails_storage_proxy_url(images.first)
    elsif room_images.any?
      room_images.first.image_url
    end
  end

  # Helper method to get optimized thumbnail URL
  def thumbnail_url_medium
    if images.attached?
      begin
        variant_url(images.first, resize_to_limit: [800, 600]) || thumbnail_url
      rescue => e
        Rails.logger.error "Error in thumbnail_url_medium: #{e.message}"
        thumbnail_url
      end
    elsif room_images.any?
      room_images.first.image_url
    end
  end

  # Helper method to get small thumbnail URL
  def thumbnail_url_thumb
    if images.attached?
      begin
        variant_url(images.first, resize_to_limit: [400, 300]) || thumbnail_url
      rescue => e
        Rails.logger.error "Error in thumbnail_url_thumb: #{e.message}"
        thumbnail_url
      end
    elsif room_images.any?
      room_images.first.image_url
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
      # Process variant synchronously to avoid HTTP/2 protocol errors
      # This ensures the variant is ready before returning the URL
      variant = attachment.variant(transformations)
      
      # Process the variant to ensure it exists before generating URL
      # This prevents ERR_HTTP2_PROTOCOL_ERROR when the variant isn't ready
      processed_variant = variant.processed
      
      Rails.application.routes.url_helpers.rails_storage_proxy_url(processed_variant, host: host, protocol: 'https')
    rescue LoadError => e
      # If vips/image_processing library is missing, fallback to original
      Rails.logger.error "Image processing library not available: #{e.message}"
      rails_storage_proxy_url(attachment)
    rescue ActiveStorage::FileNotFoundError, MiniMagick::Error, ImageProcessing::Error => e
      Rails.logger.error "Error processing variant: #{e.message}. Falling back to original."
      rails_storage_proxy_url(attachment)
    rescue => e
      Rails.logger.error "Error generating variant URL: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
      # Fallback to original image
      rails_storage_proxy_url(attachment)
    end
  end

  private

  private

  def set_defaults
    self.active = true if active.nil?
    self.status ||= 'available'
    self.has_sound_system = false if has_sound_system.nil?
    self.has_projector = false if has_projector.nil?
    self.has_karaoke = false if has_karaoke.nil?
    self.position ||= Room.maximum(:position).to_i + 1
  end

  def handle_position_change
    return if new_record?
    
    old_pos = position_was
    new_pos = position
    
    # Clamp new position to valid range
    max_pos = Room.count
    new_pos = [[new_pos, 1].max, max_pos].min
    self.position = new_pos
    
    if old_pos && new_pos && old_pos != new_pos
      if new_pos < old_pos
        # Moving up: shift items in between down
        Room.where("position >= ? AND position < ? AND id != ?", new_pos, old_pos, id)
            .update_all("position = position + 1")
      else
        # Moving down: shift items in between up
        Room.where("position > ? AND position <= ? AND id != ?", old_pos, new_pos, id)
            .update_all("position = position - 1")
      end
    end
  end

  def reorder_all_positions
    # After delete, reindex all remaining rooms
    Room.order(:position, :id).each_with_index do |room, index|
      new_position = index + 1
      room.update_column(:position, new_position) if room.position != new_position
    end
  end
end
