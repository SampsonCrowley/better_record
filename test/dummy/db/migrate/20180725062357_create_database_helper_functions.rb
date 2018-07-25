class CreateDatabaseHelperFunctions < ActiveRecord::Migration[5.2]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin;"
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

    sql = ""
    source = File.new(Rails.root.join('db', 'postgres-audit-trigger.psql'), "r")
    while (line = source.gets)
      sql << line.gsub(/SELECTED_SCHEMA_NAME/, BetterRecord.db_audit_schema)
    end
    source.close

    execute sql

    execute <<-SQL
      CREATE OR REPLACE FUNCTION hash_password(password text)
        RETURNS text AS
      $BODY$
      BEGIN
        password = crypt(password, gen_salt('bf', 8));

        RETURN password;
      END;
      $BODY$

      LANGUAGE plpgsql;
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION validate_email(email text)
        RETURNS text AS
      $BODY$
      BEGIN
        IF email IS NOT NULL THEN
          IF email !~* '\\A[^@\\s\\;]+@[^@\\s\\;]+\\.[^@\\s\\;]+\\Z' THEN
            RAISE EXCEPTION 'Invalid E-mail format %', email
                USING HINT = 'Please check your E-mail format.';
          END IF ;
          email = lower(email);
        END IF ;

        RETURN email;
      END;
      $BODY$
      LANGUAGE plpgsql;
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION valid_email_trigger()
        RETURNS TRIGGER AS
      $BODY$
      BEGIN
        NEW.email = validate_email(NEW.email);

        RETURN NEW;
      END;
      $BODY$
      LANGUAGE plpgsql;
    SQL

  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS valid_email_trigger();
      DROP FUNCTION IF EXISTS validate_email();
      execute "DROP FUNCTION IF EXISTS hash_password();"
      execute "DROP EXTENSION IF EXISTS pgcrypto;"
      DROP SCHEMA IF EXISTS #{ENV.fetch('DB_AUDIT_SCHEMA') { 'audit' }} CASCADE;
      execute "DROP EXTENSION IF EXISTS btree_gin;"
      execute "DROP EXTENSION IF EXISTS pg_trgm;"
    SQL
  end
end
