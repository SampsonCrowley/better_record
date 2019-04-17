# frozen_string_literal: true
require 'store_as_int'

module BetterRecord
  module MoneyInteger
    def self.convert_to_money(value)
      return StoreAsInt::Money.new(0) unless value
      if (!value.kind_of?(Numeric))
        begin
          dollars_to_cents = (value.gsub(/\$/, '').presence || 0).to_d * StoreAsInt::Money.base
          StoreAsInt::Money.new(dollars_to_cents.to_i)
        rescue
          StoreAsInt::Money.new
        end
      else
        StoreAsInt::Money.new(value)
      end
    end

    module TableDefinition
      def money_integer(*args, **opts)
        args.each do |name|
          column name, :money_integer, **opts
        end
      end
    end

    class Type < BetterRecord::CustomType
      def self.normalize_type_value(value)
        BetterRecord::MoneyInteger.convert_to_money(value)
      end

      def self.serialize(value)
        normalize_type_value(value).value
      end
    end
  end
end
