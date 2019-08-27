# frozen_string_literal: true

module BetterRecord
  module Migration
    def audit_table(table_name, rows = nil, query_text = nil, skip_columns = %w[ updated_at ])
      reversible do |d|
        d.up do
          if(rows && rows.is_a?(Array))
            skip_columns = rows
            rows = true
            query_text = true
          end

          if rows.nil? && skip_columns.is_a?(Array)
            rows = true
            query_text = query_text.nil? ? true : query_text
          end

          if(rows.nil? )
            execute "SELECT #{BetterRecord.db_audit_schema}.audit_table('#{table_name}');"
          else
            rows = !!rows ? 't' : 'f'
            query_text = !!query_text ? 't' : 'f'
            skip_columns = skip_columns.present? ? "'{#{skip_columns.join(',')}}'" : 'ARRAY[]'
            execute "SELECT #{BetterRecord.db_audit_schema}.audit_table('#{table_name}', BOOLEAN '#{rows}', BOOLEAN '#{query_text}', #{skip_columns}::text[]);"
          end
        end

        d.down do
          execute "DROP TRIGGER IF EXISTS audit_trigger_row ON #{table_name};"
          execute "DROP TRIGGER IF EXISTS audit_trigger_stm ON #{table_name};"
        end
      end
    end

    def login_triggers(table_name, password_col = 'password', email_col = 'email', function_name = nil, in_reverse = false)
      table_name = table_name.to_s

      reversible do |d|
        d.__send__(in_reverse ? :down : :up) do
          password_text = ''

          if !!password_col
            create_pwd_txt = ->(col) {
              <<-SQL
                IF (NEW.#{col} IS NOT NULL)
                AND (
                  (TG_OP = 'INSERT') OR ( NEW.#{col} IS DISTINCT FROM OLD.#{col} )
                ) THEN
                  IF (NEW.#{col} IS DISTINCT FROM 'CLEAR_EXISTING_PASSWORD_FOR_ROW') THEN
                    NEW.#{col} = hash_password(NEW.#{col});
                  ELSE
                    NEW.#{col} = NULL;
                  END IF;
                ELSE
                  IF (TG_OP IS DISTINCT FROM 'INSERT') THEN
                    NEW.#{col} = OLD.#{col};
                  ELSE
                    NEW.#{col} = NULL;
                  END IF;
                END IF;

              SQL
            }
            password_text = password_col.is_a?(Array) ? (password_col.map {|pwd| create_pwd_txt.call(pwd)}).join("\n") : create_pwd_txt.call(password_col)
          end

          email_text = ''

          if !!email_col
            email_text = <<-SQL
              IF (TG_OP = 'INSERT') OR ( NEW.#{email_col} IS DISTINCT FROM OLD.#{email_col} ) THEN
                NEW.#{email_col} = validate_email(NEW.#{email_col});
              END IF;

            SQL
          end

          execute <<-SQL
            CREATE OR REPLACE FUNCTION #{function_name.presence || table_name.singularize}_changed()
              RETURNS TRIGGER AS
            $BODY$
            BEGIN
              #{password_text}
              #{email_text}
              RETURN NEW;
            END;
            $BODY$
            language 'plpgsql';
          SQL

          execute <<-SQL
            CREATE TRIGGER #{function_name.presence || table_name}_on_insert
            BEFORE INSERT ON #{table_name}
            FOR EACH ROW
            EXECUTE PROCEDURE #{function_name.presence || table_name.singularize}_changed();
          SQL

          execute <<-SQL
            CREATE TRIGGER #{function_name.presence || table_name}_on_update
            BEFORE UPDATE ON #{table_name}
            FOR EACH ROW
            EXECUTE PROCEDURE #{function_name.presence || table_name.singularize}_changed();

          SQL
        end

        d.__send__(in_reverse ? :up : :down) do
          execute "DROP TRIGGER IF EXISTS #{function_name.presence || table_name}_on_insert ON #{table_name};"
          execute "DROP TRIGGER IF EXISTS #{function_name.presence || table_name}_on_update ON #{table_name};"
        end
      end
    end
  end
end
