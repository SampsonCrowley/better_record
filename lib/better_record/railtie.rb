module BetterRecord
  class Railtie < ::Rails::Railtie
    rake_tasks do
      puts 'BetterRecord::Railtie RAKE TASKS'
      Dir[File.expand_path('tasks/**/*.rake', __dir__)].each do |f|
        puts f
        load f
      end
    end
  end
end
