# frozen_string_literal: true

class PasswordsMailer < ApplicationMailer
  def reset(user)
    @token = user.generate_token_for(:password_reset)
    mail to: user.email_address, subject: I18n.t("passwords.title")
  end
end
