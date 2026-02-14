# frozen_string_literal: true

require "test_helper"

class WorkerTimelinePolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "all roles can index worker timelines" do
    assert WorkerTimelinePolicy.new(@admin, :worker_timeline).index?
    assert WorkerTimelinePolicy.new(@owner, :worker_timeline).index?
    assert WorkerTimelinePolicy.new(@manager, :worker_timeline).index?
  end

  test "all roles can show worker timelines" do
    assert WorkerTimelinePolicy.new(@admin, :worker_timeline).show?
    assert WorkerTimelinePolicy.new(@owner, :worker_timeline).show?
    assert WorkerTimelinePolicy.new(@manager, :worker_timeline).show?
  end
end
