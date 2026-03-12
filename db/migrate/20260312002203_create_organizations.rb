class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.integer :status,      null: false, default: 0
      t.string  :owner_email, null: false
      t.string  :phone
      t.jsonb   :settings,    null: false, default: {}
      t.timestamps
    end

    add_index :organizations, :slug,     unique: true
    add_index :organizations, :status
    add_index :organizations, :settings, using: :gin
  end
end
