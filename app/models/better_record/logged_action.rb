# frozen_string_literal: true

module BetterRecord
  class LoggedAction < Base
    # == Constants ============================================================
    ACTIONS = {
      D: 'DELETE',
      I: 'INSERT',
      U: 'UPDATE',
      T: 'TRUNCATE',
      A: 'ARCHIVE',
    }.with_indifferent_access

    # == Attributes ===========================================================
    self.table_name = "#{BetterRecord.db_audit_schema}.logged_actions_view"

    # == Extensions ===========================================================

    # == Relationships ========================================================
    belongs_to :audited,
      polymorphic: :true,
      primary_type: :table_name,
      foreign_key: :row_id,
      foreign_type: :table_name,
      optional: true

    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Boolean Class Methods ================================================

    # == Class Methods ========================================================
    def self.default_print
      [
        :event_id,
        :row_id,
        :table_name,
        :app_user_id,
        :app_user_type,
        :action_type,
        :changed_columns
      ]
    end

    # def self.set_audits_methods!
    #   self.has_many self.audit_relation_name,
    #     class_name: 'BetterRecord::LoggedAction',
    #     primary_type: :table_name,
    #     foreign_key: :row_id,
    #     foreign_type: :table_name,
    #     as: self.audit_relation_name
    # end

    # == Boolean Methods ======================================================

    # == Instance Methods =====================================================
    def changed_columns
      (self.changed_fields || {}).keys.join(', ').presence || 'N/A'
    end

    def action_type
      ACTIONS[action] || 'UNKNOWN'
    end

  end
end
