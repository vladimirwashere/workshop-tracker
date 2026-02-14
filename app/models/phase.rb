# frozen_string_literal: true

class Phase < ApplicationRecord
  include Discard::Model
  include Auditable
  include DateRangeValidatable
  include Statusable

  belongs_to :project
  has_many :tasks, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validates :planned_start_date, presence: true
  validates :planned_end_date, presence: true
  validate :dates_within_project_range
end
