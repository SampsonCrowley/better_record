# frozen_string_literal: true

module BetterRecord
  class Railtie < ::Rails::Railtie
    rake_tasks do
      Dir[File.expand_path('tasks/**/*.rake', __dir__)].each do |f|
        load f
      end
    end
  end
end
