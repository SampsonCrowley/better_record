module BetterRecord
  module Rspec
    module Extensions
    end
  end
end

Dir.glob("#{File.expand_path(__dir__)}/extensions/*").each do |d|
  require d
end
