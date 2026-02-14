# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module BahWorkshopTracker
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    # Collapse policy concerns so they autoload at the top level (matching models/controllers behavior)
    config.autoload_paths << Rails.root.join("app/policies/concerns")

    initializer "collapse_policy_concerns", before: :set_autoload_paths do
      Rails.autoloaders.main.collapse("#{root}/app/policies/concerns")
    end

    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en]
    config.i18n.fallbacks = true
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    config.active_job.queue_adapter = :solid_queue

    config.generators do |g|
      g.test_framework :minitest, fixture: false
      g.factory_bot dir: "test/factories"
    end
  end
end
