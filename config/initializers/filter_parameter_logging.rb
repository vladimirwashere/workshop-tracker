# frozen_string_literal: true

# Filter sensitive parameters from logs (see ActiveSupport::ParameterFilter).
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :temp_password
]
