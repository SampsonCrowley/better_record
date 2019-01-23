# frozen_string_literal: true
require 'store_as_int'

module BetterRecord
  module ExchangeRateInteger
    module TableDefinition
      def exchange_rate_integer(*args, **opts)
        args.each do |name|
          column name, :exchange_rate_integer, **opts
        end
      end
    end

    class Type < ActiveRecord::Type::Value
      def cast(value)
        convert_to_exchange_rate(value)
      end

      def deserialize(value)
        super(convert_to_exchange_rate(value))
      end

      def serialize(value)
        super(convert_to_exchange_rate(value).value)
      end

      private
        def convert_to_exchange_rate(value)
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
    end
  end
end
