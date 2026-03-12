class User < ApplicationRecord
  include Discard::Model

  belongs_to :organization, optional: true

  has_secure_password

  enum :role, { participant: 0, admin: 1, super_admin: 2 }, default: :participant

  validates :name,  presence: true, length: { maximum: 100 }
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
