# frozen_string_literal: true

ActiveRecord::Type.register(:exchange_rate_integer, BetterRecord::ExchangeRateInteger::Type)
