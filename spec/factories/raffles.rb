FactoryBot.define do
  factory :raffle do
    association :organization
    association :lottery

    title        { Faker::Commerce.product_name }
    description  { Faker::Lorem.sentence }
    ticket_price { Faker::Commerce.price(range: 5.0..100.0) }
    draw_mode    { :centena }
    status       { :draft }
    draw_date    { Date.current + 30.days }

    trait(:draft)     { status { :draft } }
    trait(:open)      { status { :open } }
    trait(:closed)    { status { :closed } }
    trait(:drawn)     { status { :drawn } }
    trait(:cancelled) { status { :cancelled } }

    trait(:milhar)           { draw_mode { :milhar } }
    trait(:dezena_de_milhar) { draw_mode { :dezena_de_milhar } }

    trait(:with_prizes) do
      after(:create) do |raffle|
        create(:raffle_prize, raffle: raffle, position: 1, lottery_prize_position: 1)
        create(:raffle_prize, raffle: raffle, position: 2, lottery_prize_position: 2)
      end
    end
  end
end
