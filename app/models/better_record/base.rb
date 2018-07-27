module BetterRecord
  class Base < ActiveRecord::Base
    self.abstract_class = true

    # == Constants ============================================================

    # == Attributes ===========================================================

    # == Extensions ===========================================================

    # == Relationships ========================================================
    if (ha = BetterRecord.has_auditing_relation_by_default)
      has_many self.audit_relation_name,
        class_name: 'BetterRecord::LoggedAction',
        primary_type: :table_name,
        foreign_key: :row_id,
        foreign_type: :table_name,
        as: self.audit_relation_name
    end
    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Class Methods ========================================================

    # == Instance Methods =====================================================

  end
end
