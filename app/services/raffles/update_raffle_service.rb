module Raffles
  class UpdateRaffleService
    def initialize(raffle, params)
      @raffle = raffle
      @params = params
    end

    def call
      unless @raffle.draft? || @raffle.open?
        return { success: false, raffle: @raffle, errors: [ "Raffle cannot be updated in #{@raffle.status} status" ] }
      end

      update_params = allowed_params

      if @raffle.update(update_params)
        { success: true, raffle: @raffle }
      else
        { success: false, raffle: @raffle, errors: @raffle.errors.full_messages }
      end
    end

    private

    def allowed_params
      permitted = @params.slice(
        :title, :description, :ticket_price, :draw_date, :raffle_prizes_attributes
      )

      # draw_mode only allowed in draft
      permitted[:draw_mode] = @params[:draw_mode] if @raffle.draft? && @params.key?(:draw_mode)

      permitted
    end
  end
end
