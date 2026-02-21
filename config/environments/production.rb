require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # Do not serve static files (Render handles it)
  config.public_file_server.enabled = false

  # Logging
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"

  config.active_support.report_deprecations = false

  # ActiveStorage (temporary local — later move to S3)
  config.active_storage.service = :local

  # Simple cache
  config.cache_store = :memory_store

  # 🔥 Use async instead of SolidQueue (NO worker needed)
  config.active_job.queue_adapter = :async

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # Allow Render domain
  config.hosts << "ai-bot-backend-u8yg.onrender.com"
end