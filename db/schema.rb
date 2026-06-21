# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_21_000002) do
  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.boolean "host", default: false, null: false
    t.string "nickname", null: false
    t.integer "progress", default: 0, null: false
    t.integer "room_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "token"], name: "index_players_on_room_id_and_token", unique: true
    t.index ["room_id"], name: "index_players_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "prompt_text"
    t.datetime "started_at"
    t.string "status", default: "waiting", null: false
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["code"], name: "index_rooms_on_code", unique: true
    t.index ["winner_id"], name: "index_rooms_on_winner_id"
  end

  add_foreign_key "players", "rooms"
end
