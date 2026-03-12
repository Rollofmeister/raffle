class LotterySchedule < ApplicationRecord
  belongs_to :lottery
  has_many :draws, dependent: :destroy

  validates :draw_time, presence: true
  validates :draw_time, uniqueness: { scope: :lottery_id }

  scope :active, -> { where(active: true) }

  def today_draw
    draws.find_by(draw_date: Date.today)
  end

  def draw_time_passed_today?
    return false unless active?
    Time.current.strftime("%H:%M") >= draw_time
  end
end
