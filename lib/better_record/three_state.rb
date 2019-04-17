# encoding: utf-8
# frozen_string_literal: true

module BetterRecord
  module ThreeState
    ENUM = {
      Y: 'Y',
      y: 'Y',
      Yes: 'Y',
      yes: 'Y',
      T: 'Y',
      t: 'Y',
      True: 'Y',
      true: 'Y',
      true => 'Y',
      N: 'N',
      n: 'N',
      No: 'N',
      no: 'N',
      F: 'N',
      f: 'N',
      False: 'N',
      false: 'N',
      false => 'N',
      U: 'U',
      u: 'U',
      Unknown: 'U',
      unknown: 'U',
    }.freeze

    TITLECASE = {
      'Y' => 'Yes',
      'N' => 'No',
      'U' => 'Unknown',
    }.freeze

    def self.titleize(category)
      TITLECASE[convert_to_three_state(category) || 'U']
    end

    def self.convert_to_three_state(value)
      case value.to_s.downcase
      when /^(?:y|t(rue)?$)/
        'Y'
      when /^(?:n|f(alse)?$)/
        'N'
      else
        'U'
      end
    end

    module TableDefinition
      def three_state(*args, **opts)
        args.each do |name|
          column name, :three_state, **opts
        end
      end
    end

    class Type < BetterRecord::CustomType
      def self.normalize_type_value(value)
        BetterRecord::ThreeState.convert_to_three_state(value)
      end
    end
  end
end
