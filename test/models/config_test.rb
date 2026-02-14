# frozen_string_literal: true

require "test_helper"

class ConfigTest < ActiveSupport::TestCase
  test "requires key" do
    config = Config.new(key: nil, value: "test")
    assert_not config.valid?
  end

  test "key must be unique" do
    Config.create!(key: "unique_test_key", value: "a")
    config = Config.new(key: "unique_test_key", value: "b")
    assert_not config.valid?
  end

  test "get returns value for key" do
    Config.create!(key: "my_key", value: "my_value")
    assert_equal "my_value", Config.get("my_key")
  end

  test "get returns default when key missing" do
    assert_equal "fallback", Config.get("nonexistent", "fallback")
  end

  test "set creates or updates config" do
    Config.set("new_key", "new_value")
    assert_equal "new_value", Config.get("new_key")

    Config.set("new_key", "updated_value")
    assert_equal "updated_value", Config.get("new_key")
  end
end
