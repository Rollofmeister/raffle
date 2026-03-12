class RafflePrize < ApplicationRecord
  belongs_to :raffle

  validates :position,               presence: true,
                                     numericality: { only_integer: true, in: 1..5 },
                                     uniqueness: { scope: :raffle_id }
  validates :description,            presence: true, length: { maximum: 255 }
  validates :lottery_prize_position, presence: true,
                                     numericality: { only_integer: true, in: 1..5 }
end
