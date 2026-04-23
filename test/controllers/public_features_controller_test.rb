require "test_helper"

class PublicFeaturesControllerTest < ActionDispatch::IntegrationTest
  test "renders public feature details" do
    feature = create(:ticket, :feature, title: "Public feature", description: "Detailed public description")

    get public_feature_url(feature)

    assert_response :success
    assert_includes response.body, feature.title
    assert_includes response.body, feature.description
    assert_select "a[href=?]", roadmap_path, text: /Back to roadmap/
  end

  test "404s for private feature requests" do
    feature = create(:ticket, :feature, public_on_roadmap: false)

    assert_raises(ActiveRecord::RecordNotFound) do
      get public_feature_url(feature)
    end
  end

  test "404s for non-feature public roadmap items" do
    task = create(:ticket, classification: :task, public_on_roadmap: true, title: "Roadmap task")

    assert_raises(ActiveRecord::RecordNotFound) do
      get public_feature_url(task)
    end
  end
end
