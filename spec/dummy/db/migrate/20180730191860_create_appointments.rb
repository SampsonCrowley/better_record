class CreateAppointments < ActiveRecord::Migration[5.2]
  def change
    create_table :appointments do |t|
      t.references :client, foreign_key: true
      t.text :title
      t.text :description
      t.datetime :starting, index: true
      t.datetime :ending, index: true

      t.timestamps default: -> { 'NOW()' }
    end

    audit_table :appointments
  end
end
