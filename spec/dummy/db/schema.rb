# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181128220352) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "provider"
    t.integer "synced_id"
    t.string "name"
    t.string "oauth_access_token"
    t.string "oauth_refresh_token"
    t.string "oauth_expires_at"
    t.string "host"
    t.index ["synced_id"], name: "index_accounts_on_synced_id"
  end

  create_table "applications", force: :cascade do |t|
    t.string "host"
    t.text "client_id"
    t.text "client_secret"
  end

end
