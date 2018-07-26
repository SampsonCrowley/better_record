require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require "better_record"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.eager_load_paths += Dir["#{config.root}/lib/modules/**/"]
    config.active_record.schema_format = :sql
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
