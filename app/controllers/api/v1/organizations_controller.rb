module Api
  module V1
    class OrganizationsController < ApplicationController
      before_action :require_admin!
      before_action :set_organization

      def update_logo
        unless params[:logo].present?
          render json: { error: "No file provided" }, status: :unprocessable_entity and return
        end

        processed = ImageProcessor.call(params[:logo])
        @organization.logo.attach(
          io: processed,
          filename: "logo.webp",
          content_type: "image/webp"
        )

        render json: { logo_url: url_for(@organization.logo) }, status: :ok
      end

      def destroy_logo
        @organization.logo.purge_later
        head :no_content
      end

      private

      def set_organization
        @organization = current_organization
      end
    end
  end
end
