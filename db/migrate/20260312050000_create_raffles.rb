class CreateRaffles < ActiveRecord::Migration[8.0]
  def change
    create_table :raffles do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :lottery,      null: false, foreign_key: true
      t.string  :title,           null: false
      t.text    :description
      t.decimal :ticket_price,    null: false, precision: 10, scale: 2
      t.integer :draw_mode,       null: false
      t.integer :status,          null: false, default: 0
      t.date    :draw_date,       null: false
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :raffles, :status
    add_index :raffles, :draw_date
    add_index :raffles, :discarded_at
  end
end
