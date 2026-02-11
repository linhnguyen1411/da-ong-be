class Admin < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  ROLES = %w[super_admin admin manager receptionist staff].freeze
  validates :role, presence: true, inclusion: { in: ROLES }

  before_validation :set_default_role, on: :create

  scope :active, -> { where(active: true) }

  def effective_role
    role == 'staff' ? 'receptionist' : role
  end

  def admin_role?
    %w[admin super_admin].include?(effective_role)
  end

  def manager_role?
    effective_role == 'manager'
  end

  def receptionist_role?
    effective_role == 'receptionist'
  end

  private

  def set_default_role
    self.role ||= 'admin'
  end
end
