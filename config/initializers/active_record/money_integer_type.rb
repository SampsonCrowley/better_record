# frozen_string_literal: true

ActiveRecord::Type.register(:money_integer, BetterRecord::MoneyInteger::Type)
