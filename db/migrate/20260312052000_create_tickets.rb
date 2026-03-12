class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.references :raffle, null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.string  :number,           null: false
      t.integer :status,           null: false, default: 0
      t.datetime :reserved_until
      t.string  :payment_method
      t.string  :payment_reference
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :tickets, [ :raffle_id, :number ], unique: true
    add_index :tickets, :status
    add_index :tickets, :reserved_until
    add_index :tickets, :discarded_at
  end
end
