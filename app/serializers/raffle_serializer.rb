class RaffleSerializer
  def initialize(raffle)
    @raffle = raffle
  end

  def serializable_hash
    {
      id:           @raffle.id,
      title:        @raffle.title,
      description:  @raffle.description,
      ticket_price: @raffle.ticket_price.to_s,
      draw_mode:    @raffle.draw_mode,
      status:       @raffle.status,
      draw_date:    @raffle.draw_date,
      total_tickets: @raffle.total_tickets,
      lottery_id:   @raffle.lottery_id,
      prizes:       serialize_prizes,
      created_at:   @raffle.created_at,
      updated_at:   @raffle.updated_at
    }
  end

  private

  def serialize_prizes
    @raffle.raffle_prizes.order(:position).map do |prize|
      {
        id:                    prize.id,
        position:              prize.position,
        description:           prize.description,
        lottery_prize_position: prize.lottery_prize_position
      }
    end
  end
end
