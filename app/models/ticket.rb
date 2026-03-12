class Ticket < ApplicationRecord
  include Discard::Model

  belongs_to :raffle
  belongs_to :user

  enum :status, { reserved: 0, paid: 1, expired: 2, cancelled: 3 }, default: :reserved

  PAYMENT_METHODS = %w[gateway manual].freeze

  validates :number, presence: true, uniqueness: { scope: :raffle_id }
end
