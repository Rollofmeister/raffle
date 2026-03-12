module Api
  module V1
    class RafflesController < ApplicationController
      before_action :set_raffle, only: [ :show, :update, :destroy, :open, :close ]

      def index
        scope = if current_user.admin? || current_user.super_admin?
          current_organization.raffles.kept
        else
          current_organization.raffles.for_participants
        end

        result = paginate(scope.order(created_at: :desc))
        render json: {
          raffles: result[:records].map { |r| RaffleSerializer.new(r).serializable_hash },
          meta: result[:meta]
        }
      end

      def show
        render json: { raffle: RaffleSerializer.new(@raffle).serializable_hash }
      end

      def create
        require_admin!
        return if performed?

        result = Raffles::CreateRaffleService.new(raffle_params, current_organization).call

        if result[:success]
          render json: { raffle: RaffleSerializer.new(result[:raffle]).serializable_hash },
                 status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def update
        require_admin!
        return if performed?

        result = Raffles::UpdateRaffleService.new(@raffle, raffle_params).call

        if result[:success]
          render json: { raffle: RaffleSerializer.new(result[:raffle]).serializable_hash }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def destroy
        require_admin!
        return if performed?

        unless @raffle.draft?
          render json: { errors: [ "Only draft raffles can be deleted" ] }, status: :unprocessable_entity
          return
        end

        @raffle.discard
        head :no_content
      end

      def open
        require_admin!
        return if performed?

        result = Raffles::TransitionRaffleService.new(@raffle, :open).call
        render_transition_result(result)
      end

      def close
        require_admin!
        return if performed?

        result = Raffles::TransitionRaffleService.new(@raffle, :closed).call
        render_transition_result(result)
      end

      private

      def set_raffle
        @raffle = current_organization.raffles.kept.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Raffle not found" }, status: :not_found
      end

      def raffle_params
        params.permit(
          :title, :description, :ticket_price, :draw_mode, :draw_date, :lottery_id,
          raffle_prizes_attributes: [ :id, :position, :description, :lottery_prize_position, :_destroy ]
        )
      end

      def render_transition_result(result)
        if result[:success]
          render json: { raffle: RaffleSerializer.new(result[:raffle]).serializable_hash }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end
    end
  end
end
