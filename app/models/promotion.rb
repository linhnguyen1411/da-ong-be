# frozen_string_literal: true

class Promotion < ApplicationRecord
  validates :title, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }
  scope :highlighted, -> { where(highlighted: true) }
end
