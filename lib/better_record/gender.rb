# frozen_string_literal: true

module BetterRecord
  module Gender
    ENUM = {
      F: 'F',
      M: 'M',
      f: 'F',
      m: 'M',
      female: 'F',
      Female: 'F',
      male: 'M',
      Male: 'M',
    }.freeze

    module TableDefinition
      def gender(*args, **opts)
        args.each do |name|
          column name, :gender, **opts
        end
      end
    end

    class Type < ActiveRecord::Type::Value

      def cast(value)
        convert_to_gender(value)
      end

      def deserialize(value)
        super(convert_to_gender(value))
      end

      def serialize(value)
        super(convert_to_gender(value))
      end

      private
        def convert_to_gender(value)
          case value.to_s
          when /^[Mm]/
            'M'
          when /^[Ff]/
            'F'
          else
            nil
          end
        end
    end
  end
end
