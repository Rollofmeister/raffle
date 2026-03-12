FactoryBot.define do
  factory :user do
    association :organization
    name     { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    email    { Faker::Internet.email }
    password { "password123" }
    role     { :participant }
    phone    { Faker::PhoneNumber.cell_phone }

    trait(:admin)       { role { :admin } }
    trait(:super_admin) do
      role         { :super_admin }
      organization { nil }
    end
  end
end
