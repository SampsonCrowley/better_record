module BetterRecord
  class Current < ActiveSupport::CurrentAttributes
    attribute :user, :ip_address
  end
end
