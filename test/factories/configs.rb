# frozen_string_literal: true

FactoryBot.define do
  factory :config do
    sequence(:key) { |n| "test_config_#{n}" }
    value { "test_value" }
  end
end
