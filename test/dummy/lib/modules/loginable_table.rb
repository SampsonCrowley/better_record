module LoginableTable
  extend ActiveSupport::Concern

  def login_triggers(table_name, password_col = 'password', email_col = 'email')
    table_name = table_name.to_s

    reversible do |d|
      d.up do
        password_text = ''

        if !!password_col
          password_text = <<-SQL
            IF (NEW.#{password_col} IS NOT NULL)
            AND (
              (TG_OP = 'INSERT') OR ( NEW.#{password_col} IS DISTINCT FROM OLD.#{password_col} )
            ) THEN
              NEW.#{password_col} = hash_password(NEW.#{password_col});
            ELSE
              IF (TG_OP IS DISTINCT FROM 'INSERT') THEN
                NEW.#{password_col} = OLD.#{password_col};
              ELSE
                NEW.#{password_col} = NULL;
              END IF;
            END IF;

          SQL
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
          CREATE OR REPLACE FUNCTION #{table_name.singularize}_changed()
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
          CREATE TRIGGER #{table_name}_on_insert
          BEFORE INSERT ON #{table_name}
          FOR EACH ROW
          EXECUTE PROCEDURE #{table_name.singularize}_changed();
        SQL

        execute <<-SQL
          CREATE TRIGGER #{table_name}_on_update
          BEFORE UPDATE ON #{table_name}
          FOR EACH ROW
          EXECUTE PROCEDURE #{table_name.singularize}_changed();

        SQL
      end

      d.down do
        execute "DROP TRIGGER IF EXISTS #{table_name}_on_insert ON #{table_name};"
        execute "DROP TRIGGER IF EXISTS #{table_name}_on_update ON #{table_name};"
      end
    end
  end
end
