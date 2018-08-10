Dir.glob("#{File.expand_path(__dir__)}/expectations/*").each do |d|
  require d
end
