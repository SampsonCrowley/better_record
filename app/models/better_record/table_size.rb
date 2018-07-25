module BetterRecord
  class TableSize < Base
    # == Constants ============================================================
    CREATE_TABLE_SQL = <<-SQL
      DROP TABLE IF EXISTS table_sizes;
      CREATE TEMPORARY TABLE table_sizes AS (
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
      )
    SQL

    # == Attributes ===========================================================
    self.primary_key = :oid
    self.table_name = 'table_sizes'

    # == Extensions ===========================================================

    # == Relationships ========================================================

    # == Validations ==========================================================

    # == Scopes ===============================================================
    default_scope { where(schema: [ :public ]) }
    # == Callbacks ============================================================

    # == Class Methods ========================================================
    def self.load_schema(reload = false)
      unless @loaded_schema && !reload
        connection.execute CREATE_TABLE_SQL
        @loaded_schema = true
      end

      super()
    end

    def self.find_by(*args)
      load_schema(true)
      super *args
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
