Dir[File.expand_path('../lib/better_record/rspec/*.rb', __dir__)].each do |file|
  require file
end

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('dummy/config/environment.rb', __dir__)
require 'rspec/rails'
require 'factory_bot_rails'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.add_setting :quick_unique, default: (ENV['UNSAFE_UNIQUE'] == 'true')

  config.include FactoryBot::Syntax::Methods
  config.extend BetterRecord::Rspec::Extensions

  config.exclude_pattern = '**/dummy/**/*spec*'
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.use_transactional_fixtures = true

  config.infer_base_class_for_anonymous_controllers = false

  config.order = "random"

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.fail_fast = true
end
