class CreateLotterySchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :lottery_schedules do |t|
      t.references :lottery, null: false, foreign_key: true
      t.string :draw_time, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :lottery_schedules, [ :lottery_id, :draw_time ], unique: true
  end
end
