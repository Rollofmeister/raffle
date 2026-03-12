FactoryBot.define do
  factory :ticket do
    association :raffle
    association :user

    sequence(:number) { |n| n.to_s.rjust(2, "0") }
    status         { :reserved }
    reserved_until { 30.minutes.from_now }
    payment_method { nil }

    trait(:reserved)  { status { :reserved } }
    trait(:paid)      { status { :paid } }
    trait(:expired)   { status { :expired } }
    trait(:cancelled) { status { :cancelled } }
  end
end
