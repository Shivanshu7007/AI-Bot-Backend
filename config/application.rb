require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module KinshipBackend
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    # ❗ Disable sprockets (important)
    config.assets.enabled = false

    # Allow React public build files
    config.public_file_server.enabled = true
  end
end