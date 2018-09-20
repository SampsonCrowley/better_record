# frozen_string_literal: true

module BetterRecord
  module Gender
    ENUM = {
      f: 'F',
      F: 'F',
      female: 'F',
      Female: 'F',
      m: 'M',
      M: 'M',
      male: 'M',
      Male: 'M',
      u: 'U',
      U: 'U',
      unknown: 'U',
      Unknown: 'F'
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
          when /[Ff]/
            'F'
          when /[Mm]/
            'M'
          else
            'U'
          end
        end
    end
  end
end
