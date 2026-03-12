class Organization < ApplicationRecord
  enum :status, { pending: 0, active: 1, suspended: 2 }, default: :pending

  has_one_attached :logo
  has_many :users,   dependent: :destroy
  has_many :raffles, dependent: :destroy

  validates :name,        presence: true, length: { maximum: 100 }
  validates :slug,        presence: true,
                          uniqueness: { case_sensitive: false },
                          format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens" },
                          length: { maximum: 63 }
  validates :owner_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status,      presence: true

  before_validation :normalize_slug

  private

  def normalize_slug
    self.slug = slug&.downcase&.strip
  end
end
