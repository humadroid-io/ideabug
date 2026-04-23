require "test_helper"

class RoadmapPresenterTest < ActiveSupport::TestCase
  test "splits public roadmap tickets across now/next/shipped/ideas" do
    in_progress = create(:ticket, :feature, status: :in_progress)
    sched_a = create(:ticket, :feature, scheduled_for: 1.week.from_now)
    sched_b = create(:ticket, :feature, scheduled_for: 3.weeks.from_now)
    shipped = create(:ticket, :feature, shipped_at: 2.days.ago, status: :completed)
    idea_high = create(:ticket, :feature)
    idea_low = create(:ticket, :feature)
    create(:ticket_vote, ticket: idea_high)

    create(:ticket, :feature, public_on_roadmap: false, title: "Hidden")

    out = RoadmapPresenter.call

    assert_equal [in_progress.id], out[:now].map(&:id)
    assert_equal [sched_a.id, sched_b.id], out[:next].map(&:id)
    assert_equal [shipped.id], out[:shipped].map(&:id)
    assert_equal [idea_high.id, idea_low.id], out[:ideas].map(&:id)
  end

  test "scheduled_for trumps in_progress: ticket with a date appears in next, not now" do
    started_and_scheduled = create(:ticket, :feature, status: :in_progress, scheduled_for: 1.week.from_now)

    out = RoadmapPresenter.call

    assert_includes out[:next].map(&:id), started_and_scheduled.id
    refute_includes out[:now].map(&:id), started_and_scheduled.id
  end

  test "in_progress without a scheduled date stays in now" do
    started_no_date = create(:ticket, :feature, status: :in_progress, scheduled_for: nil)

    out = RoadmapPresenter.call

    assert_includes out[:now].map(&:id), started_no_date.id
    refute_includes out[:next].map(&:id), started_no_date.id
  end

  test "limits ideas to default" do
    create_list(:ticket, RoadmapPresenter::DEFAULT_IDEAS_LIMIT + 3, :feature)

    out = RoadmapPresenter.call
    assert_equal RoadmapPresenter::DEFAULT_IDEAS_LIMIT, out[:ideas].size
  end

  test "honors custom ideas_limit + shipped_limit" do
    create_list(:ticket, 15, :feature)
    15.times { create(:ticket, :feature, shipped_at: rand(1..30).days.ago, status: :completed) }

    out = RoadmapPresenter.call(ideas_limit: 5, shipped_limit: 5)
    assert_equal 5, out[:ideas].size
    assert_equal 5, out[:shipped].size
  end
end
