require "test_helper"

class WidgetScriptTest < ActionDispatch::IntegrationTest
  test "GET /script.js delivers a bootstrap shell that references the fingerprinted widget assets" do
    get "/script.js"
    assert_response :success
    assert_match %r{javascript}, response.media_type

    body = response.body
    assert_includes body, "window.__ideabug_loaded"
    assert_match %r{/assets/ideabug_widget-[a-f0-9]+\.js}, body
    assert_match %r{/assets/ideabug_widget-[a-f0-9]+\.css}, body
    assert_includes body, "ideabugHost"
    assert_includes body, "ideabugTarget"
    assert_includes body, "IdeabugWidget.configure"
  end

  test "the precompiled widget bundle is served by Sprockets" do
    helper = ActionController::Base.helpers
    get helper.asset_path("ideabug_widget.js")
    assert_response :success
    assert_includes response.body, "IdeabugWidget"
    assert_includes response.body, "IdeabugNotifications" # back-compat shim
  end

  test "the precompiled widget stylesheet is served by Sprockets" do
    helper = ActionController::Base.helpers
    get helper.asset_path("ideabug_widget.css")
    assert_response :success
    assert_includes response.body, ".ideabug-root"
    assert_includes response.body, "--ib-accent"
  end
end
