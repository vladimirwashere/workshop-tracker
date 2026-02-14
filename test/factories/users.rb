# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:display_name) { |n| "User #{n}" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "Password123" }
    password_confirmation { "Password123" }
    role { :admin }
    active { true }
    confirmed_at { Time.current }

    trait :admin do
      role { :admin }
    end

    trait :owner do
      role { :owner }
    end

    trait :manager do
      role { :manager }
    end

    trait :inactive do
      active { false }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
