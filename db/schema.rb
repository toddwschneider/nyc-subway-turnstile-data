# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_10_02_103104) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "stations", force: :cascade do |t|
    t.text "name", null: false
    t.text "line_names", null: false
    t.text "division", null: false
    t.text "borough", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "subregion"
    t.index ["borough"], name: "index_stations_on_borough"
    t.index ["name", "line_names", "division"], name: "index_stations_on_name_and_line_names_and_division", unique: true
    t.index ["subregion"], name: "index_stations_on_subregion"
  end

  create_table "turnstile_observations", force: :cascade do |t|
    t.text "control_area", null: false
    t.text "unit", null: false
    t.text "scp", null: false
    t.text "station", null: false
    t.text "line_names", null: false
    t.text "division", null: false
    t.datetime "observed_at", null: false
    t.text "description", null: false
    t.bigint "entries", null: false
    t.bigint "exits", null: false
    t.bigint "net_entries"
    t.bigint "net_exits"
    t.text "filename", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["control_area", "scp", "observed_at", "description"], name: "index_turnstile_observations_unique", unique: true
    t.index ["division"], name: "index_turnstile_observations_on_division"
    t.index ["filename"], name: "index_turnstile_observations_on_filename"
    t.index ["station", "line_names", "division"], name: "index_turnstile_observations_on_subway_station"
  end

end
