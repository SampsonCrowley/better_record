module BetterRecord
  class Audit < Base
    # == Constants ============================================================
    ACTIONS = {
      D: 'DELETE',
      I: 'INSERT',
      U: 'UPDATE',
      T: 'TRUNCATE',
    }.with_indifferent_access

    # == Attributes ===========================================================
    self.table_name = 'audit.logged_actions'

    # == Extensions ===========================================================

    # == Relationships ========================================================
    belongs_to :audited,
      polymorphic: :true,
      primary_type: :table_name,
      foreign_key: :row_id,
      foreign_type: :table_name
    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

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

    # == Instance Methods =====================================================
    def changed_columns
      (self.changed_fields || {}).keys.join(', ').presence || 'N/A'
    end

    def action_type
      ACTIONS[action] || 'UNKNOWN'
    end
  end
end
