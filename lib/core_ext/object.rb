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

  def yes_no_to_s
    !!self == self ? (self ? 'yes' : 'no') : to_s
  end
end
