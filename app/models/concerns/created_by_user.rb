# frozen_string_literal: true

module CreatedByUser
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by_user, class_name: "User", inverse_of: :"created_#{model_name.element.pluralize}"
  end
end
