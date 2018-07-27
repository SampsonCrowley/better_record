module Current
  # == Constants ============================================================

  # == Attributes ===========================================================

  # == Extensions ===========================================================

  # == Relationships ========================================================

  # == Validations ==========================================================

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  # == Class Methods ========================================================
  def self.user=(user)
    set_user(user)
  end

  def self.ip_address=(user)
    set_user(user)
  end

  def self.set(user, ip)
    BetterRecord::Current.user = user.presence || nil
    BetterRecord::Current.ip_address = ip.presence || nil
  end

  def self.drop_values
    BetterRecord::Current.user = nil
    BetterRecord::Current.ip_address = nil
  end
  
  # == Instance Methods =====================================================

end
