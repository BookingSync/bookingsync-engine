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

ActiveRecord::Schema.define(version: 2019_06_23_220132) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.integer "synced_id"
    t.string "name"
    t.string "oauth_access_token"
    t.string "oauth_refresh_token"
    t.string "oauth_expires_at"
    t.integer "customized_key"
    t.index ["synced_id"], name: "index_accounts_on_synced_id"
  end

  create_table "applications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "host", null: false
    t.text "client_id", null: false
    t.text "client_secret", null: false
    t.index ["client_id"], name: "index_applications_on_client_id", unique: true
    t.index ["client_secret"], name: "index_applications_on_client_secret", unique: true
    t.index ["host"], name: "index_applications_on_host", unique: true
  end

  create_table "multi_applications_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.integer "synced_id"
    t.string "name"
    t.string "oauth_access_token"
    t.string "oauth_refresh_token"
    t.string "oauth_expires_at"
    t.string "host", null: false
    t.integer "customized_key"
    t.index ["host", "synced_id"], name: "index_multi_applications_accounts_on_host_and_synced_id", unique: true
    t.index ["host"], name: "index_multi_applications_accounts_on_host"
    t.index ["synced_id"], name: "index_multi_applications_accounts_on_synced_id"
  end

end
