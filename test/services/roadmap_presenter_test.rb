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

  test "limits ideas to IDEAS_LIMIT" do
    create_list(:ticket, RoadmapPresenter::IDEAS_LIMIT + 3, :feature)

    out = RoadmapPresenter.call
    assert_equal RoadmapPresenter::IDEAS_LIMIT, out[:ideas].size
  end
end
