class UpdateBetterRecordAuditFunctions < ActiveRecord::Migration[5.2]
  def up
    last_event = BetterRecord::LoggedAction.count

    execute <<-SQL
      ALTER TABLE #{BetterRecord.db_audit_schema}.logged_actions
      RENAME TO old_logged_actions
    SQL

    sql = ""
    source = File.new(BetterRecord::Engine.root.join('db', 'postgres-audit-v2-table.psql'), "r")
    while (line = source.gets)
      sql << line.gsub(/SELECTED_SCHEMA_NAME/, BetterRecord.db_audit_schema)
    end
    source.close

    execute sql

    execute <<-SQL
      ALTER SEQUENCE #{BetterRecord.db_audit_schema}.logged_actions_event_id_seq START WITH #{last_event}
    SQL

    sql = ""
    source = File.new(BetterRecord::Engine.root.join('db', 'postgres-audit-v2-trigger.psql'), "r")
    while (line = source.gets)
      sql << line.gsub(/SELECTED_SCHEMA_NAME/, BetterRecord.db_audit_schema)
    end
    source.close

    execute sql

    rows = execute <<-SQL
      select trg.tgname,
          CASE trg.tgtype::integer & 66
              WHEN 2 THEN 'BEFORE'
              WHEN 64 THEN 'INSTEAD OF'
              ELSE 'AFTER'
          end as trigger_type,
         case trg.tgtype::integer & cast(28 as int2)
           when 16 then 'UPDATE'
           when 8 then 'DELETE'
           when 4 then 'INSERT'
           when 20 then 'INSERT, UPDATE'
           when 28 then 'INSERT, UPDATE, DELETE'
           when 24 then 'UPDATE, DELETE'
           when 12 then 'INSERT, DELETE'
         end as trigger_event,
         tbl.relname as table_name,
         obj_description(trg.oid) as remarks,
           case
            when trg.tgenabled='O' then 'ENABLED'
              else 'DISABLED'
          end as status,
          case trg.tgtype::integer & 1
            when 1 then 'ROW'::text
            else 'STATEMENT'::text
          end as trigger_level
      FROM pg_trigger trg
        JOIN pg_class tbl on trg.tgrelid = tbl.oid
        JOIN pg_namespace ns ON ns.oid = tbl.relnamespace
      WHERE trg.tgname not like 'RI_ConstraintTrigger%'
        AND trg.tgname not like 'pg_sync_pg%'
    SQL

    rows.each do |r|
      if r['tgname'].to_s =~ /audit_trigger/
        execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{BetterRecord.db_audit_schema}.logged_actions_#{r['table_name']} (
            CHECK (table_name = '#{r['table_name']}')
          ) INHERITS (#{BetterRecord.db_audit_schema}.logged_actions);
        SQL

        puts "\n\nPLEASE RECREATE ALL AUDIT TRIGGERS FOR #{r['table_name']}\n\n#{r}\n\n"
      end
    end

    puts "\n\nTo insert old audits back into logged_actions run:\n\n"

    puts <<-RUBY
      class BetterRecord::OldLoggedAction < BetterRecord::Base
        self.table_name = "#{BetterRecord.db_audit_schema}.old_logged_actions"
      end

      table_list = {}

      while BetterRecord::OldLoggedAction.count > 0
        p BetterRecord::OldLoggedAction.count
        BetterRecord::OldLoggedAction.order(:event_id).limit(1500).each do |r|
          unless table_list[r.table_name]
            begin
              BetterRecord::LoggedAction.connection.execute(%Q(SELECT 1 FROM #{BetterRecord.db_audit_schema}.logged_actions_#\{r.table_name}))

              table_list[r.table_name] = Class.new(BetterRecord::Base)
              table_list[r.table_name].table_name = "#{BetterRecord.db_audit_schema}.logged_actions_#\{r.table_name}"
            rescue ActiveRecord::StatementInvalid
              table_list[r.table_name] = BetterRecord::LoggedAction
            end
          end

          BetterRecord.const_set(:NewLoggedAction, table_list[r.table_name])
          BetterRecord::NewLoggedAction.new(r.attributes).save!(validate: false)
          p BetterRecord::NewLoggedAction.count
          r.delete
        end
      end
    RUBY
  end
end
