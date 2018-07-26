class CreateTestCustomAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :test_custom_audits do |t|
      t.text :test_text
      t.date :test_date
      t.datetime :test_time
      t.text :test_skipped_column

      t.timestamps
    end
  end
end
