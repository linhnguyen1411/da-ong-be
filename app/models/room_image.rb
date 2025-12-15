class RoomImage < ApplicationRecord
  belongs_to :room

  validates :image_url, presence: true

  before_validation :set_defaults, on: :create

  scope :ordered, -> { order(position: :asc) }

  private

  def set_defaults
    self.position ||= RoomImage.where(room_id: room_id).maximum(:position).to_i + 1
  end
end
