class CreateTestAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :test_audits do |t|
      t.text :test_text
      t.date :test_date
      t.datetime :test_time

      t.timestamps
    end
  end
end
