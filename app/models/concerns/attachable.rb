# frozen_string_literal: true

module Attachable
  extend ActiveSupport::Concern

  included do
    has_many :attachments, as: :related, dependent: :destroy
  end
end
