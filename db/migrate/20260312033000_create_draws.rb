class CreateDraws < ActiveRecord::Migration[8.1]
  def change
    create_table :draws do |t|
      t.references :lottery_schedule, null: false, foreign_key: true
      t.date :draw_date, null: false
      t.jsonb :prizes, default: [], null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :draws, [ :lottery_schedule_id, :draw_date ], unique: true
    add_index :draws, :status
  end
end
