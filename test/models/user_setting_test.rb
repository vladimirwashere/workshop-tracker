# frozen_string_literal: true

require "test_helper"

class UserSettingTest < ActiveSupport::TestCase
  test "belongs to user" do
    user = create(:user)
    setting = user.user_setting
    assert_equal user, setting.user
  end

  test "default_currency_display enum" do
    user = create(:user)
    setting = user.user_setting

    assert setting.currency_RON?

    setting.update!(default_currency_display: :GBP)
    assert setting.currency_GBP?
  end

  test "last_gantt_zoom stores period days" do
    user = create(:user)
    setting = user.user_setting

    # Default is 7 (set by User#create_default_settings)
    assert_equal 7, setting.last_gantt_zoom

    setting.update!(last_gantt_zoom: 30)
    assert_equal 30, setting.reload.last_gantt_zoom

    setting.update!(last_gantt_zoom: 365)
    assert_equal 365, setting.reload.last_gantt_zoom

    # Only allowed period presets are valid
    assert_not setting.update(last_gantt_zoom: 0)
    assert_not setting.update(last_gantt_zoom: 1)
    assert_not setting.update(last_gantt_zoom: 91)
  end
end
