# frozen_string_literal: true

class DailyLog < ApplicationRecord
  include Discard::Model
  include Attachable
  include Auditable
  include CreatedByUser

  belongs_to :project
  belongs_to :task
  belongs_to :worker

  validates :log_date, presence: true
  validates :hours_worked, presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 24 }
  validates :scope, length: { maximum: 5000 }

  before_validation :default_hours

  scope :in_range, ->(from, to) { where(log_date: from..to) }

  private

  def default_hours
    self.hours_worked = 8.0 if hours_worked.blank?
  end
end
