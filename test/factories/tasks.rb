# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    project
    sequence(:name) { |n| "Task #{n}" }
    status { :planned }
    priority { :medium }
    planned_start_date { Date.current }
    planned_end_date { Date.current + 15.days }

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

    trait :with_phase do
      association :phase
      project { phase.project }
      planned_start_date { phase.planned_start_date }
      planned_end_date { phase.planned_end_date }
    end
  end
end
