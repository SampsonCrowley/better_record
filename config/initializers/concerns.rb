# frozen_string_literal: true

Dir.glob(BetterRecord::Engine.root.join('lib', 'better_record', 'concerns', '**', '*.rb')).each do |d|
  require d
end
