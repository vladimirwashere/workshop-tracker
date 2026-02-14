# frozen_string_literal: true

require "test_helper"

class CleanupExpiredSessionsJobTest < ActiveSupport::TestCase
  test "deletes expired sessions" do
    create(:session, :expired)
    create(:session, :expired)

    assert_difference "Session.count", -2 do
      CleanupExpiredSessionsJob.perform_now
    end
  end

  test "preserves active sessions" do
    active = create(:session)

    assert_no_difference "Session.count" do
      CleanupExpiredSessionsJob.perform_now
    end

    assert Session.exists?(active.id)
  end

  test "handles no expired sessions gracefully" do
    assert_nothing_raised do
      CleanupExpiredSessionsJob.perform_now
    end
  end
end
