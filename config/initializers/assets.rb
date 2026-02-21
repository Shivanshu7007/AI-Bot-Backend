# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Be sure to restart your server when you modify this file.

Rails.application.config.assets.paths << Rails.root.join("app", "assets")
Rails.application.config.assets.paths << Rails.root.join("vendor", "assets")
Rails.application.config.assets.paths << Rails.root.join("public")

Rails.application.config.assets.precompile += %w[
  *.png *.jpg *.jpeg *.svg *.gif
  *.css *.js
]