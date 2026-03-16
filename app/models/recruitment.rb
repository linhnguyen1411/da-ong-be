# frozen_string_literal: true

class Recruitment < ApplicationRecord
  validates :title, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }
end
