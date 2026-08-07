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
    assert_selector ".ideabug-panel-title", text: "Feedback"
    assert_selector "button[aria-label='Close feedback panel']"
    # Updates list is lazy-loaded after bell click; wait for it to render.
    assert_selector ".ideabug-item-title", text: "Big News", wait: 5

    panel_bottom = evaluate_script("document.querySelector('.ideabug-panel').getBoundingClientRect().bottom")
    footer_bottom = evaluate_script("document.querySelector('.ideabug-footer').getBoundingClientRect().bottom")
    assert_in_delta panel_bottom, footer_bottom, 1, "widget actions should stay pinned to the panel bottom"

    # Open modal — click the row
    find(".ideabug-item", text: "Big News").click
    assert_selector ".ideabug-modal-overlay.is-open", wait: 3
    assert_selector ".ideabug-modal-title", text: "Big News"
    # Body content is lazy-fetched on modal open; spinner appears first.
    assert_selector ".ideabug-modal-body", text: "Long form content", wait: 5

    # Close with overlay click (we click the close button instead — overlay click
    # in headless can be flaky)
    find(".ideabug-modal-close").click
    assert_no_selector ".ideabug-modal-overlay.is-open", wait: 3

    # Switch to roadmap tab and vote
    find(".ideabug-tab", text: "Roadmap").click
    assert_selector ".ideabug-roadmap-card", text: "Dark mode", wait: 3

    roadmap_footer_bottom = evaluate_script("document.querySelector('.ideabug-footer').getBoundingClientRect().bottom")
    assert_in_delta panel_bottom, roadmap_footer_bottom, 1,
      "roadmap link should stay pinned to the panel bottom"

    initial_count = @feature.reload.votes_count
    find(".ideabug-roadmap-card", text: "Dark mode").find(".ideabug-vote").click

    # Optimistic UI updates first; poll the DB for the actual server-side write.
    deadline = Time.current + 5
    while Time.current < deadline && @feature.reload.votes_count == initial_count
      sleep 0.1
    end
    assert @feature.votes_count > initial_count, "vote should increment ticket counter on server"
  end

  test "shows a focused feature and bug feedback form" do
    visit "/_test/widget_host"

    find(".ideabug-bell", wait: 5).click
    find(".ideabug-tab", text: "Share feedback").click

    assert_selector ".ideabug-form-intro", text: "What can we improve?"
    assert_button "Request a feature"
    assert_button "Report a bug"
    assert_field "Summary", placeholder: "A short, specific title"
    assert_field "Details optional"
    assert_button "Send feedback"

    form_geometry = evaluate_script(<<~JS)
      (function () {
        var body = document.querySelector(".ideabug-body").getBoundingClientRect();
        var button = document.querySelector(".ideabug-form > .ideabug-btn").getBoundingClientRect();
        return { bodyBottom: body.bottom, buttonBottom: button.bottom };
      })()
    JS
    assert_in_delta 20, form_geometry["bodyBottom"] - form_geometry["buttonBottom"], 1,
      "feedback action should stay at the bottom of the content area"

    click_button "Report a bug"
    assert_selector "[data-kind='bug'].is-active"
  end

  test "keeps update actions fixed while the announcement history scrolls" do
    16.times do |index|
      create(:announcement, title: "Archive update #{index}",
        preview: "A longer historical announcement preview", published_at: (index + 2).days.ago)
    end

    visit "/_test/widget_host"

    find(".ideabug-bell", wait: 5).click
    assert_selector ".ideabug-item-title", text: "Big News", wait: 5

    geometry = evaluate_script(<<~JS)
      (function () {
        var panel = document.querySelector(".ideabug-panel").getBoundingClientRect();
        var content = document.querySelector(".ideabug-scroll-content");
        var footer = document.querySelector(".ideabug-footer").getBoundingClientRect();
        return {
          panelBottom: panel.bottom,
          footerBottom: footer.bottom,
          contentHeight: content.clientHeight,
          contentScrollHeight: content.scrollHeight
        };
      })()
    JS

    assert_operator geometry["contentScrollHeight"], :>, geometry["contentHeight"]
    assert_in_delta geometry["panelBottom"], geometry["footerBottom"], 1,
      "scrolling update history should not move the footer"
  end

  test "marks all visible announcements as read from the updates footer" do
    second = create(:announcement, title: "Another Update",
      preview: "Second preview", published_at: 30.minutes.ago)

    visit "/_test/widget_host"

    find(".ideabug-bell", wait: 5).click

    assert_selector ".ideabug-panel.is-open", wait: 5
    assert_selector ".ideabug-item.is-unread", text: "Big News", wait: 5
    assert_selector ".ideabug-item.is-unread", text: "Another Update", wait: 5

    click_button "Mark all as read"

    deadline = Time.current + 5
    while Time.current < deadline && AnnouncementRead.count < 2
      sleep 0.1
    end

    assert_equal 2, AnnouncementRead.count
    assert AnnouncementRead.exists?(announcement_id: @announcement.id)
    assert AnnouncementRead.exists?(announcement_id: second.id)
    assert_no_selector ".ideabug-item.is-unread", wait: 5
  end

  test "custom trigger unread count hides when unread falls below zero" do
    visit "/_test/widget_host?custom_trigger=1"

    find("#feedback-trigger", wait: 5)

    deadline = Time.current + 5
    while Time.current < deadline
      state = evaluate_script(<<~JS)
        (function () {
          var el = document.querySelector("#feedback-trigger [data-ideabug-unread-count]");
          return el ? { text: el.textContent, hidden: el.hidden, ariaHidden: el.getAttribute("aria-hidden") } : null;
        })()
      JS
      break if state && state["text"] == "1" && state["hidden"] == false && state["ariaHidden"] == "false"
      sleep 0.1
    end

    initial = evaluate_script(<<~JS)
      (function () {
        var el = document.querySelector("#feedback-trigger [data-ideabug-unread-count]");
        return { text: el.textContent, hidden: el.hidden, ariaHidden: el.getAttribute("aria-hidden") };
      })()
    JS
    assert_equal "1", initial["text"]
    assert_equal false, initial["hidden"]
    assert_equal "false", initial["ariaHidden"]

    execute_script("window.IdeabugWidget.unread = -1; window.IdeabugWidget.notifyTrigger();")

    hidden = evaluate_script(<<~JS)
      (function () {
        var el = document.querySelector("#feedback-trigger [data-ideabug-unread-count]");
        return { text: el.textContent, hidden: el.hidden, ariaHidden: el.getAttribute("aria-hidden") };
      })()
    JS
    assert_equal "", hidden["text"]
    assert_equal true, hidden["hidden"]
    assert_equal "true", hidden["ariaHidden"]
  end

  test "rebinds a custom trigger after Turbo replaces it" do
    visit "/_test/widget_host?custom_trigger=1"

    assert_selector ".ideabug-root", visible: :all, wait: 5
    find("#feedback-trigger").click
    assert_selector ".ideabug-panel.is-open", wait: 5
    find(".ideabug-panel-close").click
    assert_no_selector ".ideabug-panel.is-open", wait: 3

    execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:before-cache"));
      var currentTrigger = document.querySelector("#feedback-trigger");
      currentTrigger.replaceWith(currentTrigger.cloneNode(true));
      document.dispatchEvent(new CustomEvent("turbo:render"));
    JS

    assert_selector ".ideabug-root", count: 1, visible: :all
    find("#feedback-trigger").click
    assert_selector ".ideabug-panel.is-open", wait: 3
  end

  test "boots as identified when JWT is configured during ideabug ready" do
    identified = create(:contact, :identified)
    create(:announcement_read, announcement: @announcement, contact: identified)
    anonymous_count = Contact.where(external_id: nil).count

    visit "/_test/widget_host?contact_id=#{identified.id}"

    find(".ideabug-bell", wait: 5)

    deadline = Time.current + 5
    while Time.current < deadline && evaluate_script("window.IdeabugWidget.getUnreadCount()") != 0
      sleep 0.1
    end

    state = JSON.parse(evaluate_script("localStorage.getItem('ideabug:state')"))
    assert_equal 0, evaluate_script("window.IdeabugWidget.getUnreadCount()")
    assert_equal anonymous_count, Contact.where(external_id: nil).count
    assert_nil state["anonymous_id"]
  end

  test "clears stale anonymous identity after upgrading to JWT so unread does not reappear" do
    announcement = create(:announcement, title: "Upgrade Notice",
      preview: "JWT upgrade", published_at: 20.minutes.ago)
    identified = create(:contact, :identified)
    anonymous = create(:contact, :anonymous, anonymous_id: "ib_upgrade_stale_anon_123")

    visit "/_test/widget_host?contact_id=#{identified.id}&anon_id=#{anonymous.anonymous_id}"

    find(".ideabug-bell", wait: 5).click
    assert_selector ".ideabug-item.is-unread", text: "Upgrade Notice", wait: 5

    click_button "Mark all as read"

    deadline = Time.current + 5
    while Time.current < deadline && !AnnouncementRead.exists?(announcement_id: announcement.id, contact_id: identified.id)
      sleep 0.1
    end

    assert AnnouncementRead.exists?(announcement_id: announcement.id, contact_id: identified.id)
    assert_nil Contact.find_by(id: anonymous.id)

    execute_script("window.__ideabugProvideJwt = false")
    execute_script("window.IdeabugWidget.refreshState()")

    deadline = Time.current + 5
    while Time.current < deadline
      stale = Contact.find_by(anonymous_id: anonymous.anonymous_id)
      unread = evaluate_script("window.IdeabugWidget.getUnreadCount()")
      break if stale.nil? && unread == 0
      sleep 0.1
    end

    assert_nil Contact.find_by(anonymous_id: anonymous.anonymous_id)
    assert_equal 0, evaluate_script("window.IdeabugWidget.getUnreadCount()")
  end
end
