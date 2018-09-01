class CreateBetterRecordEnumTypes < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender') THEN
            CREATE TYPE gender AS ENUM ('F', 'M');
          END IF;
        END
      $$;
    SQL

  end

  def down
    execute "DROP TYPE IF EXISTS gender;"
  end
end
