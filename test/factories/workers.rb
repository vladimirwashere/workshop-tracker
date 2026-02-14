# frozen_string_literal: true

FactoryBot.define do
  factory :worker do
    sequence(:full_name) { |n| "Worker #{n}" }
    trade { "Carpenter" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
