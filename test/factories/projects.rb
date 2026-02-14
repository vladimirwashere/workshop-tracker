# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    client_name { "Test Client" }
    status { :planned }
    planned_start_date { Date.current }
    planned_end_date { Date.current + 30.days }
    association :created_by_user, factory: :user

    trait :active do
      status { :active }
    end

    trait :completed do
      status { :completed }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
