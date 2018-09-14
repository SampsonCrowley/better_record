# frozen_string_literal: true
require 'store_as_int'

module BetterRecord
  module MoneyInteger
    module TableDefinition
      def money_integer(*args, **opts)
        args.each do |name|
          column name, :money_integer, **opts
        end
      end
    end

    class Type < ActiveRecord::Type::Value
      def cast(value)
        convert_to_money(value)
      end

      def deserialize(value)
        super(convert_to_money(value))
      end

      def serialize(value)
        super(convert_to_money(value).value)
      end

      private
        def convert_to_money(value)
          return StoreAsInt::Money.new(0) unless value
          if (!value.kind_of?(Numeric))
            begin
              dollars_to_cents = (value.gsub(/\$/, '').presence || 0).to_d * 100
              StoreAsInt.money(dollars_to_cents.to_i)
            rescue
              StoreAsInt::Money.new
            end
          else
            StoreAsInt.money(value)
          end
        end
    end
  end
end
