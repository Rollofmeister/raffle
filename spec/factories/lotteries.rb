FactoryBot.define do
  factory :lottery do
    sequence(:external_id) { |n| n }
    name { "#{Faker::Lorem.word.capitalize} Lottery" }
    abbreviation { Faker::Lorem.word.upcase[0..3] }
    active { true }

    trait(:inactive) { active { false } }
  end
end
