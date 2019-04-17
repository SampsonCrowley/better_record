# encoding: utf-8
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
      Unknown: 'U'
    }.freeze

    def self.convert_to_gender(value)
      case value.to_s
      when /^[Ff]/
        'F'
      when /^[Mm]/
        'M'
      else
        'U'
      end
    end

    module TableDefinition
      def gender(*args, **opts)
        args.each do |name|
          column name, :gender, **opts
        end
      end
    end

    class Type < BetterRecord::CustomType
      def self.normalize_type_value(value)
        BetterRecord::Gender.convert_to_gender(value)
      end
    end
  end
end
