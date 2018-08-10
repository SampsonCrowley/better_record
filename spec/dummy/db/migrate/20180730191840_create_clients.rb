class CreateClients < ActiveRecord::Migration[5.2]
  def change
    create_table :clients do |t|
      t.text :first_name, null: false, index: true
      t.text :last_name, null: false, index: true
      t.text :email, index: true
      t.text :phone, index: true
      t.text :phone_type

      t.index [ :email, :phone ], unique: true

      t.timestamps default: -> { 'NOW()' }
    end

    audit_table :clients
  end
end
