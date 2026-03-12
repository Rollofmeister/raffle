class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name,            null: false
      t.string :email,           null: false
      t.string :password_digest, null: false
      t.integer :role,           null: false, default: 0
      t.string :phone
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, [ :organization_id, :email ], unique: true
    add_index :users, :discarded_at
    add_index :users, :role
  end
end
