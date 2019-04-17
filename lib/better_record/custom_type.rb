# encoding: utf-8
# frozen_string_literal: true

module BetterRecord
  class CustomType < ActiveRecord::Type::Value
    def self.normalize_type_value(value)
      raise "Method Not Implemented"
    end

    def self.cast(value)
      self.normalize_type_value(value)
    end

    def self.deserialize(value)
      self.normalize_type_value(value)
    end

    def self.serialize(value)
      self.normalize_type_value(value)
    end

    alias :super_cast :cast
    alias :super_deserialize :deserialize
    alias :super_serialize :serialize

    def cast(value)
      super_cast(self.class.cast(value))
    end

    def deserialize(value)
      super_deserialize(self.class.deserialize(value))
    end

    def serialize(value)
      super_serialize(self.class.serialize(value))
    end

    private
      def normalize_type_value(value)
        self.class.normalize_type_value(value)
      end
  end
end
