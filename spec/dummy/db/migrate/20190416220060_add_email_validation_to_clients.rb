class AddEmailValidationToClients < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TRIGGER clients_email_insert
      BEFORE INSERT ON clients
      FOR EACH ROW
      EXECUTE PROCEDURE valid_email_trigger();
    SQL

    execute <<-SQL
      CREATE TRIGGER clients_email_update
      BEFORE UPDATE ON clients
      FOR EACH ROW
      WHEN ( NEW.email IS DISTINCT FROM OLD.email )
      EXECUTE PROCEDURE valid_email_trigger();
    SQL

    execute <<-SQL
      ALTER TABLE clients
        ADD CONSTRAINT client_email_or_phone_exists CHECK (
          (email IS NOT NULL) OR (phone IS NOT NULL)
        );
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE clients
        DROP CONSTRAINT IF EXISTS client_email_or_phone_exists;
    SQL

    execute <<-SQL
      DROP TRIGGER IF EXISTS clients_email_insert ON clients;
    SQL

    execute <<-SQL
      DROP TRIGGER IF EXISTS clients_email_update ON clients;
    SQL
  end
end
