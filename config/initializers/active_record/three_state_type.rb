# frozen_string_literal: true

ActiveRecord::Type.register(:three_state, BetterRecord::ThreeState::Type)
