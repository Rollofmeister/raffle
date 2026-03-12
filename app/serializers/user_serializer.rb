class UserSerializer
  include Alba::Resource

  attributes :id, :name, :email, :role, :phone
end
