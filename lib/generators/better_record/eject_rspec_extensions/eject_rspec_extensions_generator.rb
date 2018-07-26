class BetterRecord::EjectRspecExtensionsGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def copy_templates
    template "#{BetterRecord::Engine.root}/lib/better_record/rspec/extensions.rb", 'spec/extensions.rb'
    directory "#{BetterRecord::Engine.root}/lib/better_record/rspec/extensions", 'spec/extensions'
  end
end
