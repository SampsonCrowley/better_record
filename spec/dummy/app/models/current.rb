module Current
  # == Constants ============================================================

  # == Attributes ===========================================================

  # == Extensions ===========================================================

  # == Relationships ========================================================

  # == Validations ==========================================================

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  # == Class Methods ========================================================

  def self.user
    BetterRecord::Current.user
  end

  def self.user=(user)
    set_user(user)
  end

  def self.ip_address
    BetterRecord::Current.user
  end

  def self.ip_address=(user)
    set_user(user)
  end

  def self.user_type
    BetterRecord::Current.user_type
  end

  def self.set(user, ip)
    BetterRecord::Current.set(user, ip)
  end

  def self.drop_values
    BetterRecord::Current.drop_values
  end

  # == Instance Methods =====================================================

end
