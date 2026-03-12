class CreateLotteries < ActiveRecord::Migration[8.1]
  def change
    create_table :lotteries do |t|
      t.integer :external_id, null: false
      t.string :name, null: false
      t.string :abbreviation
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :lotteries, :external_id, unique: true
  end
end
