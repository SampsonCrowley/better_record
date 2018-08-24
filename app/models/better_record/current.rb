# frozen_string_literal: true

module BetterRecord
  class Current < ActiveSupport::CurrentAttributes
    # == Constants ============================================================

    # == Attributes ===========================================================
    attribute :user, :ip_address

    # == Extensions ===========================================================

    # == Relationships ========================================================

    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Boolean Class Methods ================================================

    # == Class Methods ========================================================
    def self.drop_values
      self.user = nil
      self.ip_address = nil
      self
    end

    def self.set(user, ip)
      self.user = user.presence || nil
      self.ip_address = ip.presence || nil
      self
    end

    def self.user_type
      BetterRecord::PolymorphicOverride.polymorphic_value(self.user.class) if self.user
    end

    # == Boolean Methods ======================================================

    # == Instance Methods =====================================================

  end
end
