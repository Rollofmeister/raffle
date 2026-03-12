class Draw < ApplicationRecord
  belongs_to :lottery_schedule

  enum :status, { pending: 0, processed: 1, failed: 2 }

  validates :draw_date, presence: true
  validates :draw_date, uniqueness: { scope: :lottery_schedule_id }

  scope :pending, -> { where(status: :pending) }
  scope :processed, -> { where(status: :processed) }

  def prize_for(position)
    prizes.find { |p| p["position"] == position }&.fetch("value", nil)
  end
end
