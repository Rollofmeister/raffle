module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate!
      before_action :set_organization
      before_action :require_organization!, only: :register

      def register
        result = Auth::RegisterUserService.new(register_params, @organization).call

        if result[:success]
          render json: {
            token: result[:token],
            user: UserSerializer.new(result[:user]).serializable_hash
          }, status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def login
        result = Auth::LoginUserService.new(params[:email], params[:password], @organization).call

        if result[:success]
          render json: {
            token: result[:token],
            user: UserSerializer.new(result[:user]).serializable_hash
          }
        else
          render json: { errors: result[:errors] }, status: :unauthorized
        end
      end

      private

      def set_organization
        organization_id = request.headers["X-Organization-Id"]
        if organization_id.present?
          @organization = Organization.active.find_by(id: organization_id)
          render json: { error: "Organization not found" }, status: :not_found unless @organization
        else
          @organization = nil
        end
      end

      def require_organization!
        render json: { error: "Organization not found" }, status: :not_found unless @organization
      end

      def register_params
        params.permit(:name, :email, :password, :phone)
      end
    end
  end
end
