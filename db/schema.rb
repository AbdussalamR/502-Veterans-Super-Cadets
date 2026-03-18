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

ActiveRecord::Schema[8.0].define(version: 2026_03_17_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.string "status", default: "absent", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["user_id", "event_id"], name: "index_attendances_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "demerits", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "given_by_id", null: false
    t.integer "value", default: 1
    t.datetime "date"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["given_by_id"], name: "index_demerits_on_given_by_id"
    t.index ["member_id"], name: "index_demerits_on_member_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title"
    t.datetime "date"
    t.string "location"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "end_time"
    t.boolean "allow_self_checkin", default: false, null: false
    t.string "checkin_passcode"
    t.boolean "is_public"
    t.string "ticket_url"
  end

  create_table "events_to_excuse", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "excuse_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_events_to_excuse_on_event_id"
    t.index ["excuse_id"], name: "index_events_to_excuse_on_excuse_id"
  end

  create_table "excuses", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.text "reason"
    t.datetime "submission_date", precision: nil
    t.string "status"
    t.datetime "reviewed_date", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "proof_link"
    t.string "officer_status"
    t.datetime "officer_reviewed_at"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "frequency"
    t.boolean "recurring", default: false, null: false
    t.string "recurring_days"
    t.time "recurring_start_time"
    t.time "recurring_end_time"
    t.index ["member_id"], name: "index_excuses_on_member_id"
  end

  create_table "reviewers_to_excuse", force: :cascade do |t|
    t.bigint "reviewer_id", null: false
    t.bigint "excuse_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["excuse_id"], name: "index_reviewers_to_excuse_on_excuse_id"
    t.index ["reviewer_id"], name: "index_reviewers_to_excuse_on_reviewer_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "full_name"
    t.string "uid"
    t.string "provider", default: "google_oauth2"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "user", null: false
    t.string "approval_status", default: "pending"
    t.string "calendar_token"
    t.bigint "section_id"
    t.index ["approval_status"], name: "index_users_on_approval_status"
    t.index ["calendar_token"], name: "index_users_on_calendar_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["section_id"], name: "index_users_on_section_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "users"
  add_foreign_key "demerits", "users", column: "given_by_id"
  add_foreign_key "demerits", "users", column: "member_id"
  add_foreign_key "events_to_excuse", "events"
  add_foreign_key "events_to_excuse", "excuses"
  add_foreign_key "excuses", "users", column: "member_id"
  add_foreign_key "reviewers_to_excuse", "excuses"
  add_foreign_key "reviewers_to_excuse", "users", column: "reviewer_id"
  add_foreign_key "users", "sections"
end
