require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Caching for performance
  config.action_controller.perform_caching = true

  # ⭐ Serve React static files
  config.public_file_server.enabled = true
  config.assets.compile = true
  config.assets.digest = true

  # Cache headers
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}"
  }

  # Active Storage
  config.active_storage.service = :local

  # SSL (Render auto-terminates SSL, but ok)
  config.assume_ssl = true
  config.force_ssl = true

  # Logging
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  # Cache + Queue
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Mailer
  config.action_mailer.default_url_options = {
    host: "ai-bot-backend-u8yg.onrender.com",
    protocol: "https"
  }

  # I18n fallback
  config.i18n.fallbacks = true

  # Schema dump
  config.active_record.dump_schema_after_migration = false

  # Only show ID in logs
  config.active_record.attributes_for_inspect = [:id]

  # Allow Render host
  config.hosts << "ai-bot-backend-u8yg.onrender.com"
end