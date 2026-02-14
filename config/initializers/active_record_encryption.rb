# frozen_string_literal: true

Rails.application.configure do
  if Rails.env.test? || ENV["SECRET_KEY_BASE_DUMMY"].present?
    # Use deterministic dummy keys for test environment and asset precompilation
    config.active_record.encryption.primary_key = "test" * 8
    config.active_record.encryption.deterministic_key = "test" * 8
    config.active_record.encryption.key_derivation_salt = "test" * 8
  else
    config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY")
    config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY")
    config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT")
  end

  # Allow reading unencrypted data during migration period
  config.active_record.encryption.support_unencrypted_data = true
end
