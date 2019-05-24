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

  def self.const_belongs_to_parent?(sym)
    (
      self.superclass &&
      self.superclass.const_defined?(sym) &&
      (
        self.superclass.const_get(sym) == self.const_get(sym)
      )
    )
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
    !!self == self ? BetterRecord::ThreeState.titleize(self) : to_s
  end

  def y_n_to_s
    !!self == self ? BetterRecord::ThreeState.convert_to_three_state(self) : to_s
  end
end
