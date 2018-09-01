# frozen_string_literal: true

ActiveRecord::Type.register(:gender, BetterRecord::Gender::Type)
