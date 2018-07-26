puts "AHHHHHHH"
Dir.glob("#{File.expand_path(__dir__)}/method_helper/*").each do |d|
  require d
end

module MethodHelper
end
