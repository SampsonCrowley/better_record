class CreateDevelopers < ActiveRecord::Migration[5.2]
  def change
    create_table :developers do |t|
      t.string :email, null: false
      t.text :password, null: false
      t.text :first, null: false
      t.text :middle
      t.text :last, null: false
      t.text :suffix
      t.gender :gender, null: false
      t.date :dob, null: false
      t.text :text_array, null: false, array:true, default: []
      t.integer :int_array, null: false, array:true, default: []
      t.jsonb :json_col, null: false, default: {}
      t.boolean :bool_col, null: false, default: false
      t.three_state :three_state_col, null: false, default: 'U'
      t.money_integer :money_col

      t.timestamps default: -> { 'NOW()' }

      t.index [ :email ], unique: true
    end

    audit_table :developers, true, false, %w(password)
    login_triggers :developers
  end
end
