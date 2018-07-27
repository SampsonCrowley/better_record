class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.string :description
      t.date :due_date, index: true
      t.references :developer, index: true, foreign_key: true

      t.timestamps default: -> { 'NOW()' }
    end

    audit_table :tasks
  end
end
