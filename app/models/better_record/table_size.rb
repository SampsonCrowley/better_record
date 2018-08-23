# frozen_string_literal: true

module BetterRecord
  class TableSize < Base
    # == Constants ============================================================
    UPDATE_TABLE_SIZES_SQL = <<-SQL
      BEGIN WORK;
        LOCK TABLE #{BetterRecord.db_audit_schema}.table_sizes;
        TRUNCATE TABLE #{BetterRecord.db_audit_schema}.table_sizes;
        INSERT INTO #{BetterRecord.db_audit_schema}.table_sizes (
          SELECT
            *,
            pg_size_pretty(total_bytes) AS total,
            pg_size_pretty(idx_bytes) AS idx,
            pg_size_pretty(toast_bytes) AS toast,
            pg_size_pretty(tbl_bytes) AS tbl
          FROM (
            SELECT
              *,
              total_bytes - idx_bytes - COALESCE(toast_bytes,0) AS tbl_bytes
            FROM (
              SELECT c.oid,nspname AS schema, relname AS name
              , c.reltuples AS row_estimate
              , pg_total_relation_size(c.oid) AS total_bytes
              , pg_indexes_size(c.oid) AS idx_bytes
              , pg_total_relation_size(reltoastrelid) AS toast_bytes
              FROM pg_class c
              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE relkind = 'r'
            ) table_sizes
          ) table_sizes
        );
      COMMIT WORK;
    SQL

    # == Attributes ===========================================================
    cattr_accessor :last_updated
    self.primary_key = :oid
    self.table_name = "#{BetterRecord.db_audit_schema}.table_sizes"

    # == Extensions ===========================================================

    # == Relationships ========================================================

    # == Validations ==========================================================

    # == Scopes ===============================================================
    default_scope { where(schema: [ :public ]) }
    # == Callbacks ============================================================

    # == Class Methods ========================================================
    def self.find_by(*args)
      reload_data
      super *args
    end

    def self.all
      reload_data if last_updated.blank? || (super.first.last_updated > 1.hour.ago)
      super
    end

    def self.reload_data
      @@last_updated ||= Time.now
      connection.execute UPDATE_TABLE_SIZES_SQL
    end

    # def self.default_print
    #   [
    #     :table_schema,
    #     :table_name,
    #     :
    #   ]
    # end

    # == Instance Methods =====================================================
    def changed_columns
      (self.changed_fields || {}).keys.join(', ').presence || 'N/A'
    end

    def action_type
      ACTIONS[action] || 'UNKNOWN'
    end
  end
end
