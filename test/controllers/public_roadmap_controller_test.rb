require "test_helper"

class PublicRoadmapControllerTest < ActionDispatch::IntegrationTest
  test "renders unauthenticated and defaults to next plus voteable ideas" do
    scheduled_feature = create(:ticket, :feature, scheduled_for: 5.days.from_now, title: "Scheduled next")
    public_feature = create(:ticket, :feature, title: "On the roadmap")
    private_feature = create(:ticket, :feature, public_on_roadmap: false, title: "Hidden idea")
    in_progress = create(:ticket, :feature, status: :in_progress, title: "In flight")
    shipped = create(:ticket, :feature, shipped_at: 1.week.ago, status: :completed, title: "Done deal")

    get "/roadmap"
    assert_response :success

    assert_select "a.tab-active", text: /Next/
    assert_includes response.body, scheduled_feature.title
    assert_includes response.body, public_feature.title
    refute_includes response.body, private_feature.title
    refute_includes response.body, in_progress.title
    refute_includes response.body, shipped.title
    refute_match %r{vote.*button}i, response.body[0, 200] # no vote buttons in markup
  end

  test "renders in progress tab on request" do
    in_progress = create(:ticket, :feature, status: :in_progress, title: "In flight")

    get "/roadmap", params: {tab: "now"}
    assert_response :success

    assert_select "a.tab-active", text: /In progress/
    assert_includes response.body, in_progress.title
  end

  test "renders shipped tab on request" do
    shipped = create(:ticket, :feature, shipped_at: 1.week.ago, status: :completed, title: "Done deal")

    get "/roadmap", params: {tab: "shipped"}
    assert_response :success

    assert_select "a.tab-active", text: /Shipped/
    assert_includes response.body, shipped.title
  end

  test "renders empty default tab gracefully" do
    get "/roadmap"
    assert_response :success
    assert_match %r{Nothing scheduled yet}, response.body
  end
end
