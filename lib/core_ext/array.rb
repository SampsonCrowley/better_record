# frozen_string_literal: true

class Array
  def to_db_enum
    hashed = {}
    each {|v| hashed[v] = v.to_s}
    hashed
  end

  def extract!
    return to_enum(:extract!) { size } unless block_given?

    extracted_elements = []

    reject! do |element|
      extracted_elements << element if yield(element)
    end

    extracted_elements
  end
end
