# frozen_string_literal: true

module StandardCrudPolicy
  extend ActiveSupport::Concern

  included do
    def index?  = true
    def show?   = true
    def create? = admin_or_manager?
    def update? = admin_or_manager?
    def destroy? = admin_or_manager?
  end
end
