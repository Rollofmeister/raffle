module Api
  module V1
    module SuperAdmin
      class OrganizationsController < ApplicationController
        before_action :require_super_admin!
        before_action :set_organization, only: [ :show, :update, :destroy ]

        def index
          result = paginate(Organization.kept.order(:name))
          render json: {
            organizations: result[:records].map { |o| OrganizationSerializer.new(o).serializable_hash },
            meta: result[:meta]
          }
        end

        def show
          render json: { organization: OrganizationSerializer.new(@organization).serializable_hash }
        end

        def create
          result = ::SuperAdmin::CreateOrganizationService.new(organization_params).call

          if result[:success]
            render json: { organization: OrganizationSerializer.new(result[:organization]).serializable_hash },
                   status: :created
          else
            render json: { errors: result[:errors] }, status: :unprocessable_entity
          end
        end

        def update
          if @organization.update(organization_params)
            render json: { organization: OrganizationSerializer.new(@organization).serializable_hash }
          else
            render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @organization.discard
          head :no_content
        end

        private

        def set_organization
          @organization = Organization.kept.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Organization not found" }, status: :not_found
        end

        def organization_params
          params.permit(:name, :slug, :owner_email, :phone, :status, settings: {})
        end
      end
    end
  end
end
