class OrganizationSerializer
  def initialize(organization)
    @organization = organization
  end

  def serializable_hash
    {
      id:          @organization.id,
      name:        @organization.name,
      slug:        @organization.slug,
      owner_email: @organization.owner_email,
      phone:       @organization.phone,
      status:      @organization.status,
      settings:    @organization.settings,
      created_at:  @organization.created_at,
      updated_at:  @organization.updated_at
    }
  end
end
