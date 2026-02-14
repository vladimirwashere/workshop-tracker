# frozen_string_literal: true

FactoryBot.define do
  factory :session do
    association :user
    ip_address { "127.0.0.1" }
    user_agent { "TestBrowser/1.0" }
    expires_at { 30.days.from_now }

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
