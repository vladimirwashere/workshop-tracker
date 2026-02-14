# frozen_string_literal: true

class AttachmentPolicy < ApplicationPolicy
  include StandardCrudPolicy

  def download?
    true
  end
end
