FactoryBot.define do
  factory :draw do
    association :lottery_schedule
    draw_date { Date.today }
    prizes do
      [
        { "position" => 1, "value" => "1234", "group_value" => "12", "group_name" => "Elefante" },
        { "position" => 2, "value" => "5678", "group_value" => "56", "group_name" => "Galo" }
      ]
    end
    status { :processed }

    trait(:pending) { status { :pending } }
    trait(:failed)  { status { :failed } }
  end
end
