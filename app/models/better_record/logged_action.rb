# frozen_string_literal: true

module BetterRecord
  class LoggedAction < Base
    # == Constants ============================================================

    # == Attributes ===========================================================
    self.table_name = "#{BetterRecord.db_audit_schema}.logged_actions_view"
    self.primary_key = :event_id

    # == Extensions ===========================================================
    include ModelConcerns::LoggedActionBase

    # == Relationships ========================================================

    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Boolean Class Methods ================================================

    # == Class Methods ========================================================

    # == Boolean Methods ======================================================

    # == Instance Methods =====================================================

  end
end
