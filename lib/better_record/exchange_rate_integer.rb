# encoding: utf-8
# frozen_string_literal: true

require 'store_as_int'

module BetterRecord
  module ExchangeRateInteger

    def self.convert_to_exchange_rate(value)
      return StoreAsInt::ExchangeRate.new(0) unless value
      if (!value.kind_of?(Numeric))
        begin
          exchange_rate_to_i = (value.gsub(/\%/, '').presence || 0).to_d * StoreAsInt::ExchangeRate.base
          StoreAsInt::ExchangeRate.new(exchange_rate_to_i.to_i)
        rescue
          StoreAsInt::ExchangeRate.new
        end
      else
        StoreAsInt::ExchangeRate.new(value)
      end
    end

    module TableDefinition
      def exchange_rate_integer(*args, **opts)
        args.each do |name|
          column name, :exchange_rate_integer, **opts
        end
      end
    end

    class Type < BetterRecord::CustomType
      def self.normalize_type_value(value)
        BetterRecord::ExchangeRateInteger.convert_to_exchange_rate(value)
      end

      def self.serialize(value)
        normalize_type_value(value).value
      end
    end
  end
end
