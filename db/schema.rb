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

ActiveRecord::Schema[8.0].define(version: 2026_04_30_000001) do
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

  create_table "admin_alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "message", null: false
    t.string "alert_type", default: "email_failure", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "read_at"], name: "index_admin_alerts_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_admin_alerts_on_user_id"
  end

  create_table "application_settings", force: :cascade do |t|
    t.integer "reminder_hours_before", default: 24, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "music_drive_url"
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

  create_table "audition_sessions", force: :cascade do |t|
    t.string "label", null: false
    t.datetime "start_datetime", null: false
    t.datetime "end_datetime", null: false
    t.string "location", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.text "message", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["read_at"], name: "index_contact_messages_on_read_at"
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
    t.datetime "reminder_sent_at"
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
    t.boolean "is_personal", default: false, null: false
    t.index ["member_id"], name: "index_excuses_on_member_id"
  end

  create_table "media_photos", force: :cascade do |t|
    t.string "page_name", default: "media", null: false
    t.string "caption"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
    t.index ["page_name", "position"], name: "index_media_photos_on_page_name_and_position"
  end

  create_table "media_videos", force: :cascade do |t|
    t.string "title"
    t.string "youtube_url", null: false
    t.string "youtube_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
  end

  create_table "page_contents", force: :cascade do |t|
    t.string "page_name", null: false
    t.string "content_key", null: false
    t.text "content_value"
    t.boolean "is_draft", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_name", "content_key", "is_draft"], name: "index_page_contents_on_page_name_and_content_key_and_is_draft", unique: true
  end

  create_table "performance_requests", force: :cascade do |t|
    t.string "name", null: false
    t.string "organization", null: false
    t.date "event_date", null: false
    t.string "location", null: false
    t.string "contact_email", null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_date"], name: "index_performance_requests_on_event_date"
    t.index ["status"], name: "index_performance_requests_on_status"
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.string "phone_number"
    t.boolean "email_notifications_enabled", default: true, null: false
    t.string "carrier"
    t.boolean "sms_notifications_enabled", default: false, null: false
    t.index ["approval_status"], name: "index_users_on_approval_status"
    t.index ["calendar_token"], name: "index_users_on_calendar_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["section_id"], name: "index_users_on_section_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_alerts", "users"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "users"
  add_foreign_key "demerits", "users", column: "given_by_id"
  add_foreign_key "demerits", "users", column: "member_id"
  add_foreign_key "events_to_excuse", "events"
  add_foreign_key "events_to_excuse", "excuses"
  add_foreign_key "excuses", "users", column: "member_id"
  add_foreign_key "reviewers_to_excuse", "excuses"
  add_foreign_key "reviewers_to_excuse", "users", column: "reviewer_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "sections"
end
