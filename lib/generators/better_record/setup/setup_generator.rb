require 'rails/generators/active_record'

class BetterRecord::SetupGenerator < ActiveRecord::Generators::Base
  source_root File.expand_path('templates', __dir__)

  argument :name, type: :string, default: 'testes'
  class_option :eject, type: :boolean, default: false

  def run_generator
    copy_templates
    copy_migrations
    gsub_files
  end

  private
    def audit_schema
      @audit_schema ||= options['audit_schema'].presence || 'auditing'
    end

    def copy_migrations
      rake("better_record:install:migrations")
    end

    def copy_templates
      template 'gitattributes', '.gitattributes'
      template 'gitignore', '.gitignore'
      template 'irbrc', '.irbrc'
      template 'jsbeautifyrc', '.jsbeautifyrc'
      template 'pryrc', '.pryrc'
      template 'rspec', '.rspec'
      template 'ruby-version', '.ruby-version'
      template 'initializer.rb', 'config/initializers/better_record.rb'
      directory "#{BetterRecord::Engine.root}/lib/templates", 'lib/templates'

      eject_files if !!options['eject']
    end

    def gsub_files
      eager_line = 'config.eager_load_paths += Dir["#{config.root}/lib/modules/**/"]'
      structure_line = 'config.active_record.schema_format'

      gsub_file 'config/application.rb', /([ \t]*?(#{Regexp.escape(eager_line)}|#{Regexp.escape(structure_line)})[ ='":]*?(rb|sql)?['"]?[ \t0-9\.]*?)\n/mi do |match|
        ""
      end

      gsub_file 'config/application.rb', /#{Regexp.escape("config.load_defaults")}[ 0-9\.]+\n/mi do |match|
        "#{match}    #{eager_line}\n    #{structure_line} = :sql\n"
      end

      gsub_file 'app/models/application_record.rb', /(#{Regexp.escape("class ApplicationRecord < ActiveRecord::Base")})/mi do |match|
        p match
        "class ApplicationRecord < BetterRecord::Base"
      end
    end

    def eject_files
      template "#{BetterRecord::Engine.root}/db/postgres-audit-trigger.psql", 'db/postgres-audit-trigger.psql'
      template "#{BetterRecord::Engine.root}/lib/better_record.rb", 'lib/better_record.rb'
      directory "#{BetterRecord::Engine.root}/lib/better_record", 'lib/better_record'
      directory "#{BetterRecord::Engine.root}/config/initializers", 'config/initializers/better_record'
      directory "#{BetterRecord::Engine.root}/app", 'app'

      gsub_file 'config/application.rb', /[ \t]*?require ['"]better_record['"][ \t0-9\.]*?\n/mi do |match|
        ""
      end

      r_line = 'require File.join(Rails.root, "lib", "better_record.rb")'
      gsub_file 'config/application.rb', /([ \t]*?#{Regexp.escape(r_line)}[ \t0-9\.]*?)\n/mi do |match|
        ""
      end

      gsub_file 'config/application.rb', /class Application.*?\n/mi do |match|
        "#{match}    #{r_line}\n"
      end
    end

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
