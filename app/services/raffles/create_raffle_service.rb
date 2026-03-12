module Raffles
  class CreateRaffleService
    def initialize(params, organization)
      @params       = params
      @organization = organization
    end

    def call
      raffle = @organization.raffles.new(raffle_params)

      if raffle.save
        { success: true, raffle: raffle }
      else
        { success: false, raffle: raffle, errors: raffle.errors.full_messages }
      end
    end

    private

    def raffle_params
      @params.slice(
        :title, :description, :ticket_price, :draw_mode, :draw_date, :lottery_id,
        :raffle_prizes_attributes
      )
    end
  end
end
