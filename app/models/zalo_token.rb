# app/models/zalo_token.rb
class ZaloToken < ApplicationRecord
  validates :access_token, presence: true
  validates :refresh_token, presence: true

  def access_token_expired?
    return true if access_token_expires_at.nil?
    access_token_expires_at <= Time.current
  end

  def refresh_token_expired?
    return true if refresh_token_expires_at.nil?
    refresh_token_expires_at <= Time.current
  end

  def self.current
    first_or_initialize
  end
end

