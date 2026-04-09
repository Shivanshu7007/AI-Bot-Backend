require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.enabled = false

  config.log_tags = [:request_id]
  logger = ActiveSupport::Logger.new(STDOUT)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"

  config.active_support.report_deprecations = false

  # ActiveStorage — documents and images are stored on Cloudinary (configured in storage.yml)
  config.active_storage.service = :cloudinary

  # Cache — use Redis if available, fall back to null_store
  redis_url = ENV["REDIS_URL"]
  if redis_url.present?
    config.cache_store = :redis_cache_store, { url: redis_url, expires_in: 1.hour }
  else
    config.cache_store = :null_store
  end

  # Jobs — use Sidekiq for async processing
  config.active_job.queue_adapter = :sidekiq

  # Disable ActionCable mount
  config.action_cable.mount_path = nil

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # Allowed hosts — add your Render domain via RAILS_HOST env var
  # e.g. RAILS_HOST=your-app.onrender.com
  config.hosts << /.*\.onrender\.com/
  config.hosts << ENV["RAILS_HOST"] if ENV["RAILS_HOST"].present?
end
