Dir.glob("#{File.expand_path(__dir__)}/functions/*").each do |d|
  puts d
  require d
end

module MethodHelper
  module Functions
  end
end
