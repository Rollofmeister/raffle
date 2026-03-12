class CreateRafflePrizes < ActiveRecord::Migration[8.0]
  def change
    create_table :raffle_prizes do |t|
      t.references :raffle, null: false, foreign_key: true
      t.integer :position,               null: false
      t.string  :description,            null: false
      t.integer :lottery_prize_position, null: false
      t.timestamps
    end

    add_index :raffle_prizes, [ :raffle_id, :position ], unique: true
  end
end
