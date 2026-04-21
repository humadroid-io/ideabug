class TestWidgetHostsController < ApplicationController
  allow_unauthenticated_access only: :show
  layout false

  def show
    contact = Contact.find_by(id: params[:contact_id]) if params[:contact_id].present?
    token = contact && JwtCredentialService.generate_token(contact)
    anon_id = params[:anon_id].presence

    render inline: <<~HTML, content_type: "text/html"
      <!doctype html>
      <html>
      <head><meta charset="utf-8"><title>Ideabug widget test host</title></head>
      <body>
        <div id="feedback" style="position:fixed;top:8px;right:8px"></div>
        #{test_widget_setup_script(token: token, anon_id: anon_id)}
        <script src="/script.js"
                data-ideabug-host=""
                data-ideabug-target="#feedback"
                defer></script>
      </body>
      </html>
    HTML
  end

  private

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
