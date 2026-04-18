class TestWidgetHostsController < ActionController::Base
  layout false

  def show
    render inline: <<~HTML, content_type: "text/html"
      <!doctype html>
      <html>
      <head><meta charset="utf-8"><title>Ideabug widget test host</title></head>
      <body>
        <div id="feedback" style="position:fixed;top:8px;right:8px"></div>
        <script src="/script.js"
                data-ideabug-host=""
                data-ideabug-target="#feedback"
                defer></script>
      </body>
      </html>
    HTML
  end
end
