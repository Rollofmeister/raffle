FactoryBot.define do
  factory :lottery_schedule do
    association :lottery
    sequence(:draw_time) { |n| format("%02d:%02d", (n % 12) + 8, (n * 20) % 60) }
    active { true }

    trait(:inactive) { active { false } }
  end
end
