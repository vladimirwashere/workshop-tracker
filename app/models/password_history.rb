# frozen_string_literal: true

class PasswordHistory < ApplicationRecord
  RETENTION_COUNT = 5

  belongs_to :user

  def self.previously_used?(user, new_password)
    user.password_histories.order(created_at: :desc).limit(RETENTION_COUNT).any? do |history|
      BCrypt::Password.new(history.password_digest).is_password?(new_password)
    end
  end
end
