class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.references :room, null: false, foreign_key: true
      t.string :nickname, null: false
      t.string :token, null: false
      t.boolean :host, null: false, default: false
      t.integer :progress, null: false, default: 0
      t.datetime :finished_at

      t.timestamps
    end
    add_index :players, [ :room_id, :token ], unique: true
  end
end
