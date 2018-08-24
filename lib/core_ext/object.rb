# frozen_string_literal: true
class Object
  def self.force_print_trace(msg = "CALLED TRACER METHOD")
    begin
      raise
    rescue
      puts ""
      puts ""
      puts "----------------"
      puts msg
      puts ""
      puts $!.backtrace
      puts ""
      puts ""
      puts "----------------"
      puts ""
      puts ""
    end
  end

  def force_print_trace(msg = "CALLED TRACER METHOD")
    begin
      raise
    rescue
      puts ""
      puts ""
      puts "----------------"
      puts msg
      puts ""
      puts $!.backtrace
      puts ""
      puts ""
      puts "----------------"
      puts ""
      puts ""
    end
  end
end
