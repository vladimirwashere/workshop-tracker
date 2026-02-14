# frozen_string_literal: true

FactoryBot.define do
  factory :phase do
    project
    sequence(:name) { |n| "Phase #{n}" }
    status { :planned }
    priority { :medium }
    planned_start_date { project.planned_start_date }
    planned_end_date { project.planned_start_date + 15.days }

    trait :in_progress do
      status { :in_progress }
    end

    trait :done do
      status { :done }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
