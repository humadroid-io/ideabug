# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Precompile the embedded widget bundle so it's available in production.
Rails.application.config.assets.precompile += %w[ideabug_widget.js ideabug_widget.css]
