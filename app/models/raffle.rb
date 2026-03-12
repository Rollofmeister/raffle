class Raffle < ApplicationRecord
  include Discard::Model

  belongs_to :organization
  belongs_to :lottery
  has_many :raffle_prizes, dependent: :destroy
  has_many :tickets, dependent: :destroy

  accepts_nested_attributes_for :raffle_prizes, allow_destroy: true, reject_if: :all_blank

  enum :draw_mode, { centena: 0, milhar: 1, dezena_de_milhar: 2 }
  enum :status, { draft: 0, open: 1, closed: 2, drawn: 3, cancelled: 4 }, default: :draft

  DRAW_MODE_TICKET_COUNTS = {
    "centena"          => 100,
    "milhar"           => 1_000,
    "dezena_de_milhar" => 10_000
  }.freeze

  ALLOWED_TRANSITIONS = {
    "draft"     => %w[open cancelled],
    "open"      => %w[closed cancelled],
    "closed"    => %w[drawn cancelled],
    "drawn"     => [],
    "cancelled" => []
  }.freeze

  validates :title,        presence: true, length: { maximum: 200 }
  validates :ticket_price, presence: true, numericality: { greater_than: 0 }
  validates :draw_mode,    presence: true
  validates :draw_date,    presence: true
  validates :lottery,      presence: true

  validate :draw_date_must_be_future, on: :create
  validate :draw_mode_immutable_after_draft, on: :update
  validate :prizes_count_within_limit

  scope :for_participants, -> { kept.open }

  def total_tickets
    DRAW_MODE_TICKET_COUNTS[draw_mode]
  end

  def may_transition_to?(new_status)
    ALLOWED_TRANSITIONS[status]&.include?(new_status.to_s)
  end

  private

  def draw_date_must_be_future
    return if draw_date.blank?

    errors.add(:draw_date, "must be in the future") if draw_date <= Date.current
  end

  def draw_mode_immutable_after_draft
    return unless draw_mode_changed?
    return if draft?

    errors.add(:draw_mode, "cannot be changed after leaving draft status")
  end

  def prizes_count_within_limit
    count = raffle_prizes.reject(&:marked_for_destruction?).size
    errors.add(:raffle_prizes, "cannot have more than 5 prizes") if count > 5
  end
end
