FactoryBot.define do
  factory :organization do
    name        { Faker::Company.name }
    slug        { "#{Faker::Lorem.word}-#{Faker::Lorem.word}" }
    owner_email { Faker::Internet.email }
    phone       { Faker::PhoneNumber.cell_phone }
    status      { :active }
    settings    { {} }

    trait(:pending)   { status { :pending } }
    trait(:suspended) { status { :suspended } }
  end
end
