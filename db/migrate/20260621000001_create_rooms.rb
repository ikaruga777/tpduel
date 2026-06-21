class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :code, null: false
      t.string :status, null: false, default: "waiting"
      t.text :prompt_text
      t.datetime :started_at
      t.integer :winner_id

      t.timestamps
    end
    add_index :rooms, :code, unique: true
    add_index :rooms, :winner_id
  end
end
