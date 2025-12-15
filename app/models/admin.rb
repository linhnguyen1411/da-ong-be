class Admin < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[super_admin admin staff] }

  before_validation :set_default_role, on: :create

  scope :active, -> { where(active: true) }

  private

  def set_default_role
    self.role ||= 'admin'
  end
end
