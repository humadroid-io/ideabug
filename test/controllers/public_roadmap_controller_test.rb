require "test_helper"

class PublicRoadmapControllerTest < ActionDispatch::IntegrationTest
  test "renders unauthenticated and includes only public roadmap items" do
    public_feature = create(:ticket, :feature, title: "On the roadmap")
    private_feature = create(:ticket, :feature, public_on_roadmap: false, title: "Hidden idea")
    in_progress = create(:ticket, :feature, status: :in_progress, title: "In flight")
    shipped = create(:ticket, :feature, shipped_at: 1.week.ago, status: :completed, title: "Done deal")

    get "/roadmap"
    assert_response :success

    assert_includes response.body, public_feature.title
    refute_includes response.body, private_feature.title
    assert_includes response.body, in_progress.title
    assert_includes response.body, shipped.title
    refute_match %r{vote.*button}i, response.body[0, 200] # no vote buttons in markup
  end

  test "renders empty lanes gracefully" do
    get "/roadmap"
    assert_response :success
    assert_match %r{Nothing here yet}, response.body
  end
end
