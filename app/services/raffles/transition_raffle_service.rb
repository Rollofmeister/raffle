module Raffles
  class TransitionRaffleService
    def initialize(raffle, target_status)
      @raffle        = raffle
      @target_status = target_status.to_s
    end

    def call
      unless @raffle.may_transition_to?(@target_status)
        return {
          success: false,
          raffle: @raffle,
          errors: [ "Cannot transition from #{@raffle.status} to #{@target_status}" ]
        }
      end

      if @raffle.update(status: @target_status)
        { success: true, raffle: @raffle }
      else
        { success: false, raffle: @raffle, errors: @raffle.errors.full_messages }
      end
    end
  end
end
