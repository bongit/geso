# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20141022074809) do

  create_table "bought_assets", force: true do |t|
    t.integer  "user_id"
    t.integer  "game_asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pay_key"
  end

  create_table "carts", force: true do |t|
    t.integer  "user_id"
    t.integer  "asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pay_key"
  end

  create_table "categories", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.string   "name"
  end

  create_table "game_assets", force: true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_name"
    t.integer  "price",            limit: 3,  default: 0, null: false
    t.string   "sales_copy"
    t.string   "sales_body"
    t.string   "sales_closing"
    t.string   "promo_url"
    t.integer  "downloaded_times",            default: 0, null: false
    t.integer  "main_category"
    t.integer  "sub_category"
    t.boolean  "make_public"
    t.integer  "license"
    t.text     "zip_includes"
    t.boolean  "file_uploaded"
    t.float    "rating",           limit: 24
  end

  add_index "game_assets", ["name"], name: "index_game_assets_on_name", using: :btree

  create_table "licenses", force: true do |t|
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "main_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relationships", force: true do |t|
    t.integer  "follower_id"
    t.integer  "followed_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "relationships", ["followed_id"], name: "index_relationships_on_followed_id", using: :btree
  add_index "relationships", ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true, using: :btree
  add_index "relationships", ["follower_id"], name: "index_relationships_on_follower_id", using: :btree

  create_table "reviews", force: true do |t|
    t.integer  "game_asset_id"
    t.integer  "reviewer_id"
    t.integer  "rating"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sub_categories", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.boolean  "admin",           default: false
    t.string   "profile_text"
    t.string   "url"
    t.string   "one_time_token"
  end

  add_index "users", ["remember_token"], name: "index_users_on_remember_token", using: :btree

end
