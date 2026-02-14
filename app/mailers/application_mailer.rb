# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{ENV.fetch('APP_HOST', 'example.com')}"
  layout "mailer"
end
