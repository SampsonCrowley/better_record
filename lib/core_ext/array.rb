# frozen_string_literal: true

class Array
  def to_enum
    hashed = {}
    each {|v| hashed[v] = v.to_s}
    hashed
  end
end
