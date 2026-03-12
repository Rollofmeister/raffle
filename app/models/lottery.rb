class Lottery < ApplicationRecord
  has_many :lottery_schedules, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
