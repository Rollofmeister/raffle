module Auth
  class RegisterUserService
    def initialize(params, organization)
      @params = params
      @organization = organization
    end

    def call
      user = @organization.users.new(
        name:     @params[:name],
        email:    @params[:email],
        password: @params[:password],
        phone:    @params[:phone]
      )

      if user.save
        token = JsonWebToken.encode({ user_id: user.id, organization_id: @organization.id })
        { success: true, user: user, token: token }
      else
        { success: false, errors: user.errors.full_messages }
      end
    end
  end
end
