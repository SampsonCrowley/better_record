module BetterRecord
  class Current < ActiveSupport::CurrentAttributes
    attribute :user, :ip_address

    def self.user_type
      BetterRecord::PolymorphicOverride.polymorphic_value(self.user.class) if self.user
    end

    def self.set(user, ip)
      self.user = user.presence || nil
      self.ip_address = ip.presence || nil
    end

    def self.drop_values
      self.user = nil
      self.ip_address = nil
    end
  end
end
