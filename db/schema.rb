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

ActiveRecord::Schema[8.0].define(version: 2026_03_18_142158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.text "note"
    t.string "status", default: "absent", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["user_id", "event_id"], name: "index_attendances_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "audition_sessions", force: :cascade do |t|
    t.string "label", null: false
    t.datetime "start_datetime", null: false
    t.datetime "end_datetime", null: false
    t.string "location", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "demerits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "date"
    t.bigint "given_by_id", null: false
    t.bigint "member_id", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.integer "value", default: 1
    t.index ["given_by_id"], name: "index_demerits_on_given_by_id"
    t.index ["member_id"], name: "index_demerits_on_member_id"
  end

  create_table "events", force: :cascade do |t|
    t.boolean "allow_self_checkin", default: false, null: false
    t.string "checkin_passcode"
    t.datetime "created_at", null: false
    t.datetime "date"
    t.text "description"
    t.datetime "end_time"
    t.boolean "is_public"
    t.string "location"
    t.string "ticket_url"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "events_to_excuse", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "excuse_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_events_to_excuse_on_event_id"
    t.index ["excuse_id"], name: "index_events_to_excuse_on_excuse_id"
  end

  create_table "excuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_date"
    t.string "frequency"
    t.bigint "member_id", null: false
    t.datetime "officer_reviewed_at"
    t.string "officer_status"
    t.string "proof_link"
    t.text "reason"
    t.boolean "recurring", default: false, null: false
    t.string "recurring_days"
    t.datetime "reviewed_date", precision: nil
    t.datetime "start_date"
    t.string "status"
    t.datetime "submission_date", precision: nil
    t.datetime "updated_at", null: false
    t.time "recurring_start_time"
    t.time "recurring_end_time"
    t.index ["member_id"], name: "index_excuses_on_member_id"
  end

  create_table "reviewers_to_excuse", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "excuse_id", null: false
    t.bigint "reviewer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["excuse_id"], name: "index_reviewers_to_excuse_on_excuse_id"
    t.index ["reviewer_id"], name: "index_reviewers_to_excuse_on_reviewer_id"
  end

  create_table "sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "approval_status", default: "pending"
    t.string "avatar_url"
    t.string "calendar_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "full_name"
    t.string "provider", default: "google_oauth2"
    t.string "role", default: "user", null: false
    t.bigint "section_id"
    t.string "uid"
    t.datetime "updated_at", null: false
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
