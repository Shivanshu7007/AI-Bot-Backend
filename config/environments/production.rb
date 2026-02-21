require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.enabled = false

  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"

  config.active_support.report_deprecations = false

  # ActiveStorage
  config.active_storage.service = :local

  # Cache + Jobs
  config.cache_store = :memory_store
  config.active_job.queue_adapter = :async

  # Disable ActionCable mount
  config.action_cable.mount_path = nil

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # 🔥 Allow ALL Render hosts
  config.hosts.clear
end