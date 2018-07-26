module BetterRecord
  class Engine < ::Rails::Engine
    isolate_namespace BetterRecord

    config.generators do |g|
      g.templates.unshift File::expand_path("../templates", File.dirname(__FILE__))
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    rake_tasks do
      Dir[File.expand_path('/tasks/**/*.rake', __dir__)].each do |f|
        load f
      end
    end
  end
end
