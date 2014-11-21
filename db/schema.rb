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

ActiveRecord::Schema.define(version: 20141115181440) do

  create_table "messages", force: true do |t|
    t.text     "msg",        null: false
    t.integer  "from_user",  null: false
    t.integer  "task_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["from_user"], name: "index_messages_on_from_user", using: :btree
  add_index "messages", ["task_id"], name: "index_messages_on_task_Id", using: :btree

  create_table "tasks", force: true do |t|
    t.string  "title",              null: false
    t.integer "priority",           null: false
    t.string  "status",   limit: 6
  end

  create_table "users", force: true do |t|
    t.string  "handle",          limit: 20
    t.integer "current_task_id"
  end

end
