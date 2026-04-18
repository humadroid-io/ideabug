require "application_system_test_case"

class WidgetTest < ApplicationSystemTestCase
  setup do
    @announcement = create(:announcement, title: "Big News",
      preview: "Important update", published_at: 1.hour.ago)
    @announcement.content = "<p>Long form content for the modal body.</p>"
    @announcement.save!

    @feature = create(:ticket, :feature, title: "Dark mode")
  end

  test "loads the bell, opens the panel, opens an announcement modal, votes on a feature" do
    visit "/_test/widget_host"

    bell = find(".ideabug-bell", wait: 5)
    bell.click

    assert_selector ".ideabug-panel.is-open", wait: 5
    assert_selector ".ideabug-item-title", text: "Big News"

    # Open modal — click the row
    find(".ideabug-item", text: "Big News").click
    assert_selector ".ideabug-modal-overlay.is-open", wait: 3
    assert_selector ".ideabug-modal-title", text: "Big News"
    assert_selector ".ideabug-modal-body", text: "Long form content"

    # Close with overlay click (we click the close button instead — overlay click
    # in headless can be flaky)
    find(".ideabug-modal-close").click
    assert_no_selector ".ideabug-modal-overlay.is-open", wait: 3

    # Switch to roadmap tab and vote
    find(".ideabug-tab", text: "Roadmap").click
    assert_selector ".ideabug-roadmap-card", text: "Dark mode", wait: 3

    initial_count = @feature.reload.votes_count
    find(".ideabug-roadmap-card", text: "Dark mode").find(".ideabug-vote").click

    # Optimistic UI updates first; poll the DB for the actual server-side write.
    deadline = Time.current + 5
    while Time.current < deadline && @feature.reload.votes_count == initial_count
      sleep 0.1
    end
    assert @feature.votes_count > initial_count, "vote should increment ticket counter on server"
  end
end
