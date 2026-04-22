class TestWidgetHostsController < ApplicationController
  allow_unauthenticated_access only: :show
  layout false

  def show
    contact = Contact.find_by(id: params[:contact_id]) if params[:contact_id].present?
    token = contact && JwtCredentialService.generate_token(contact)
    anon_id = params[:anon_id].presence
    use_custom_trigger = params[:custom_trigger].present?

    render inline: <<~HTML, content_type: "text/html"
      <!doctype html>
      <html>
      <head><meta charset="utf-8"><title>Ideabug widget test host</title></head>
      <body>
        #{widget_mount_html(use_custom_trigger: use_custom_trigger)}
        #{test_widget_setup_script(token: token, anon_id: anon_id)}
        <script src="/script.js"
                data-ideabug-host=""
                #{widget_binding_attributes(use_custom_trigger: use_custom_trigger)}
                defer></script>
      </body>
      </html>
    HTML
  end

  private

  def widget_mount_html(use_custom_trigger:)
    return '<div id="feedback" style="position:fixed;top:8px;right:8px"></div>' unless use_custom_trigger

    <<~HTML.squish
      <button id="feedback-trigger" type="button" style="position:fixed;top:8px;right:8px">
        Feedback
        <span data-ideabug-unread-count hidden aria-hidden="true"></span>
      </button>
    HTML
  end

  def widget_binding_attributes(use_custom_trigger:)
    return 'data-ideabug-target="#feedback"' unless use_custom_trigger

    'data-ideabug-trigger="#feedback-trigger"'
  end

  def test_widget_setup_script(token:, anon_id:)
    return "".html_safe unless token || anon_id

    <<~HTML.html_safe
      <script>
        (function () {
          var state = { v: 1#{anon_id ? ", anonymous_id: #{anon_id.to_json}" : ""} };
          localStorage.setItem("ideabug:state", JSON.stringify(state));
          window.__ideabugProvideJwt = true;
          window.__ideabugJwtToken = #{token.to_json};

          document.addEventListener("ideabug:ready", function () {
            if (!window.__ideabugJwtToken) return;

            window.IdeabugWidget.configure({
              jwt: function () {
                return window.__ideabugProvideJwt ? window.__ideabugJwtToken : null;
              }
            });
          });
        })();
      </script>
    HTML
  end
end
