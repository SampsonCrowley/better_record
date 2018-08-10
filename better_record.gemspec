$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "better_record/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "better_record"
  s.version     = BetterRecord::VERSION
  s.authors     = ["Sampson Crowley"]
  s.email       = ["sampsonsprojects@gmail.com"]
  s.homepage    = "https://github.com/SampsonCrowley/multi_app_active_record"
  s.summary     = "Fix functions that are lacking in Active record to be compatible with multi-app databases"
  s.description = <<-BODY
  This app extends active record to allow you to change the polymorphic type value in relationships.
  It also extends active record batching functions to be able to order records while batching.
    - As a bonus. the same 'split_batches' function is made available to Arrays
  It also adds optional auditing functions and password hashing functions, as well as migration helpers
  BODY
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  # s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 5.2", '>= 5.2.0'
  s.add_dependency "pg", "~> 1.0", '>= 1.0.0'
  s.add_dependency 'store_as_int', '~> 0.0', '>= 0.0.15'
  s.add_dependency 'pry-rails', '~> 0.3', '>=0.3.6'
  s.add_dependency 'table_print', '~> 1.5', '>= 1.5.6'
  s.add_dependency 'jwt', '~> 2.1', '>= 2.1.0'
  s.add_dependency 'jwe', '~> 0.3', '>= 0.3.1'
  s.add_dependency 'csv', '~> 3.0', '>=3.0.0'

  s.add_development_dependency 'rspec-rails', '~> 3.7', '>= 3.7.2'
  # s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_bot_rails', '~> 4.10', '>= 4.10.0'
end
