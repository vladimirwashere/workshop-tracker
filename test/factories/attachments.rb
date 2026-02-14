# frozen_string_literal: true

FactoryBot.define do
  factory :attachment do
    sequence(:file_name) { |n| "photo_#{n}.jpg" }
    mime_type { "image/jpeg" }
    uploaded_at { Time.current }
    association :related, factory: :daily_log
    association :uploaded_by_user, factory: :user

    after(:build) do |attachment|
      next if attachment.file_name.nil?

      attachment.file.attach(
        io: StringIO.new("fake image data"),
        filename: attachment.file_name,
        content_type: attachment.mime_type
      )
    end

    trait :png do
      sequence(:file_name) { |n| "image_#{n}.png" }
      mime_type { "image/png" }

      after(:build) do |attachment|
        attachment.file.attach(
          io: StringIO.new("fake png data"),
          filename: attachment.file_name,
          content_type: "image/png"
        )
      end
    end

    trait :pdf do
      sequence(:file_name) { |n| "document_#{n}.pdf" }
      mime_type { "application/pdf" }

      after(:build) do |attachment|
        attachment.file.attach(
          io: StringIO.new("fake pdf data"),
          filename: attachment.file_name,
          content_type: "application/pdf"
        )
      end
    end

    trait :for_task do
      association :related, factory: :task
    end

    trait :for_daily_log do
      association :related, factory: :daily_log
    end

    trait :for_material_entry do
      association :related, factory: :material_entry
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
