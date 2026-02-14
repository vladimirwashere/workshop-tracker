# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with all attributes" do
    user = build(:user)
    assert user.valid?
  end

  test "requires email_address" do
    user = build(:user, email_address: nil)
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires unique email_address" do
    create(:user, email_address: "test@example.com")
    user = build(:user, email_address: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "normalizes email_address to lowercase" do
    user = create(:user, email_address: "  TEST@Example.COM  ")
    assert_equal "test@example.com", user.email_address
  end

  test "requires valid email format" do
    user = build(:user, email_address: "not-an-email")
    assert_not user.valid?
  end

  test "requires password minimum 8 characters" do
    user = build(:user, password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "requires role" do
    user = build(:user, role: nil)
    assert_not user.valid?
  end

  test "role enum values" do
    assert_equal 0, User.roles[:admin]
    assert_equal 1, User.roles[:owner]
    assert_equal 2, User.roles[:manager]
  end

  test "role predicate methods" do
    admin = build(:user, :admin)
    owner = build(:user, :owner)
    manager = build(:user, :manager)

    assert admin.admin?
    assert owner.owner?
    assert manager.manager?
  end

  test "creates default user_setting on create" do
    user = create(:user)
    assert_not_nil user.user_setting
    assert_equal "RON", user.user_setting.default_currency_display
  end

  test "requires display_name" do
    user = build(:user, display_name: nil)
    assert_not user.valid?
    assert_includes user.errors[:display_name], "can't be blank"
  end

  test "display_name returns stored value" do
    user = build(:user, display_name: "Vladimir Pirvu")
    assert_equal "Vladimir Pirvu", user.display_name
  end

  test "confirmed? returns true when confirmed_at present" do
    user = build(:user, confirmed_at: Time.current)
    assert user.confirmed?
  end

  test "confirmed? returns false when confirmed_at nil" do
    user = build(:user, :unconfirmed)
    assert_not user.confirmed?
  end

  test "generate_confirmation_token! sets token" do
    user = create(:user)
    assert_nil user.confirmation_token
    user.generate_confirmation_token!
    assert_not_nil user.confirmation_token
  end

  test "soft delete with discard" do
    user = create(:user)
    user.discard
    assert user.discarded?
    assert_not_nil user.discarded_at
    assert_not User.kept.include?(user)
  end

  test "has_secure_password authenticates" do
    user = create(:user, password: "Password123", password_confirmation: "Password123")
    assert user.authenticate("Password123")
    assert_not user.authenticate("wrongpassword")
  end

  test "generates_token_for password_reset" do
    user = create(:user)
    token = user.generate_token_for(:password_reset)
    assert_not_nil token

    found = User.find_by_token_for(:password_reset, token)
    assert_equal user, found
  end
end
