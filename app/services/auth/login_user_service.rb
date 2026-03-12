module Auth
  class LoginUserService
    def initialize(email, password, organization = nil)
      @email        = email&.downcase&.strip
      @password     = password
      @organization = organization
    end

    def call
      user = if @organization
        @organization.users.kept.find_by(email: @email)
      else
        User.super_admin.kept.find_by(email: @email, organization_id: nil)
      end

      if user&.authenticate(@password)
        token = JsonWebToken.encode({ user_id: user.id, organization_id: @organization&.id })
        { success: true, user: user, token: token }
      else
        { success: false, errors: [ "Invalid email or password" ] }
      end
    end
  end
end
