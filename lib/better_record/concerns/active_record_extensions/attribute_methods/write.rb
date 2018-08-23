# frozen_string_literal: true

module BetterRecord
  module AttributeMethods
    module Write
      extend ActiveSupport::Concern

      def _write_attribute(attr_name, value)
        if should_normalize? attr_name
          super(attr_name, normalize_attribute_value(attr_name, value))
        else
          super(attr_name, value)
        end
      end

      def normalize_attribute_value(attr_name, value)
        case type_for_attribute(attr_name)
        when ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array
          [value].flatten.select(&:present?)
        when ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb
          value.presence || {}
        when ActiveRecord::Type::Boolean
          BetterRecord.strict_booleans ? Boolean.strict_parse(value) : Boolean.parse(value)
        else
          value.presence
        end
      end

      def should_normalize?(attr_name)
        if !respond_to?(:normalize_columns?) || normalize_columns?
          if respond_to?(:normalized_columns)
            normalized_columns.is_a?(Array) ?
            normalized_columns.include?(attr_name.to_sym) :
            normalized_columns[attr_name]
          else
            true
          end
        else
          false
        end
      end
    end
  end
end
