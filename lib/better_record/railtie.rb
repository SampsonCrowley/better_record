# frozen_string_literal: true

module BetterRecord
  class Railtie < ::Rails::Railtie
    rake_tasks do
      Dir[File.expand_path('tasks/**/*.rake', __dir__)].each do |f|
        load f
      end
    end

    initializer 'better_record.after_app' do |app|
      app.config.after_initialize do
        if BetterRecord.session_class.is_a?(String)
          BetterRecord.session_class = BetterRecord.session_class.constantize
        end
        ActiveSupport.run_load_hooks(:better_record, BetterRecord)
      end
    end
  end
end
