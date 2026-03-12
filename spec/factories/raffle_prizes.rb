FactoryBot.define do
  factory :raffle_prize do
    association :raffle

    sequence(:position) { |n| (n % 5) + 1 }
    description            { Faker::Commerce.product_name }
    lottery_prize_position { 1 }
  end
end
