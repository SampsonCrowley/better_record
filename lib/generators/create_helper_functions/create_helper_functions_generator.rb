# frozen_string_literal: true

require 'rails/generators/active_record'

class CreateHelperFunctionsGenerator < ActiveRecord::Generators::Base
  source_root File.expand_path('templates', __dir__)
  argument :name, type: :string, default: 'testes'
  class_option :audit_schema, type: :string, default: 'audit'
  class_option :eject, type: :boolean, default: false

  def copy_initializer
    template 'gitattributes', '.gitattributes'
    template 'gitignore', '.gitignore'
    template 'jsbeautifyrc', '.jsbeautifyrc'
    template 'pryrc', '.pryrc'
    template 'ruby-version', '.ruby-version'
    template 'postgres-audit-trigger.psql', 'db/postgres-audit-trigger.psql'
    if !!options['eject']
      template 'initializer.rb', 'config/initializers/better_record.rb'
    else
      template 'initializer.rb', 'config/initializers/better_record.rb'
    end
    migration_template "migration.rb", "#{migration_path}/create_database_helper_functions.rb", migration_version: migration_version, force: true
    application ''

    eager_line = 'config.eager_load_paths += Dir["#{config.root}/lib/modules/**/"]'

    gsub_file 'config/application.rb', /([ \t]*?#{Regexp.escape(eager_line)}[ \t0-9\.]*?)\n/mi do |match|
      ""
    end

    gsub_file 'config/application.rb', /#{Regexp.escape("config.load_defaults")}[ 0-9\.]+\n/mi do |match|
      "#{match}    #{'config.eager_load_paths += Dir["#{config.root}/lib/modules/**/"]'}\n"
    end

    gsub_file 'app/models/application_record.rb', /(#{Regexp.escape("class ApplicationRecord < ActiveRecord::Base")})/mi do |match|
      p match
      "class ApplicationRecord < BetterRecord::Base"
    end
  end

  def audit_schema
    @audit_schema ||= options['audit_schema'].presence || 'audit'
  end

  private

    def migration_path
      if Rails.version >= '5.0.3'
        db_migrate_path
      else
        @migration_path ||= File.join("db", "migrate")
      end
    end

    def migration_version
      if Rails.version.start_with? '5'
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
end
