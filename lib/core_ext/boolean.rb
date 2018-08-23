# frozen_string_literal: true

require 'active_record'

class Boolean
  def self.parse(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def self.strict_parse(value)
    !!parse(value)
  end
end

class Object
  def yes_no_to_s
    !!self == self ? (self ? 'yes' : 'no') : to_s
  end
end
