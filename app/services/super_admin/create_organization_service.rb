module SuperAdmin
  class CreateOrganizationService
    def initialize(params)
      @params = params
    end

    def call
      organization = Organization.new(
        name:        @params[:name],
        slug:        @params[:slug],
        owner_email: @params[:owner_email],
        phone:       @params[:phone],
        status:      @params[:status] || :pending,
        settings:    @params[:settings] || {}
      )

      if organization.save
        { success: true, organization: organization }
      else
        { success: false, errors: organization.errors.full_messages }
      end
    end
  end
end
