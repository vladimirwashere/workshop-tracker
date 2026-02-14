# frozen_string_literal: true

FactoryBot.define do
  factory :daily_log do
    project
    task
    worker
    log_date { Date.current }
    hours_worked { 8.0 }
    scope { "Work completed" }
    association :created_by_user, factory: :user

    after(:build) do |log|
      log.task.update!(project: log.project) if log.task.project != log.project
    end
  end
end
