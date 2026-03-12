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

ActiveRecord::Schema[8.1].define(version: 2026_03_12_052000) do
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

  create_table "draws", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "draw_date", null: false
    t.bigint "lottery_schedule_id", null: false
    t.jsonb "prizes", default: [], null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["lottery_schedule_id", "draw_date"], name: "index_draws_on_lottery_schedule_id_and_draw_date", unique: true
    t.index ["lottery_schedule_id"], name: "index_draws_on_lottery_schedule_id"
    t.index ["status"], name: "index_draws_on_status"
  end

  create_table "lotteries", force: :cascade do |t|
    t.string "abbreviation"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "external_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_lotteries_on_external_id", unique: true
  end

  create_table "lottery_schedules", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "draw_time", null: false
    t.bigint "lottery_id", null: false
    t.datetime "updated_at", null: false
    t.index ["lottery_id", "draw_time"], name: "index_lottery_schedules_on_lottery_id_and_draw_time", unique: true
    t.index ["lottery_id"], name: "index_lottery_schedules_on_lottery_id"
  end

  create_table "motor_alert_locks", force: :cascade do |t|
    t.bigint "alert_id", null: false
    t.datetime "created_at", null: false
    t.string "lock_timestamp", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_id", "lock_timestamp"], name: "index_motor_alert_locks_on_alert_id_and_lock_timestamp", unique: true
    t.index ["alert_id"], name: "index_motor_alert_locks_on_alert_id"
  end

  create_table "motor_alerts", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.boolean "is_enabled", default: true, null: false
    t.string "name", null: false
    t.text "preferences", null: false
    t.bigint "query_id", null: false
    t.text "to_emails", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_alerts_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["query_id"], name: "index_motor_alerts_on_query_id"
    t.index ["updated_at"], name: "index_motor_alerts_on_updated_at"
  end

  create_table "motor_api_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "credentials", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name", null: false
    t.text "preferences", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["name"], name: "motor_api_configs_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "motor_audits", force: :cascade do |t|
    t.string "action"
    t.string "associated_id"
    t.string "associated_type"
    t.string "auditable_id"
    t.string "auditable_type"
    t.text "audited_changes"
    t.text "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.bigint "version", default: 0
    t.index ["associated_type", "associated_id"], name: "motor_auditable_associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "motor_auditable_index"
    t.index ["created_at"], name: "index_motor_audits_on_created_at"
    t.index ["request_uuid"], name: "index_motor_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "motor_auditable_user_index"
  end

  create_table "motor_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.index ["key"], name: "index_motor_configs_on_key", unique: true
    t.index ["updated_at"], name: "index_motor_configs_on_updated_at"
  end

  create_table "motor_dashboards", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.text "preferences", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "motor_dashboards_title_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["updated_at"], name: "index_motor_dashboards_on_updated_at"
  end

  create_table "motor_forms", force: :cascade do |t|
    t.string "api_config_name", null: false
    t.text "api_path", null: false
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "http_method", null: false
    t.string "name", null: false
    t.text "preferences", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_forms_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["updated_at"], name: "index_motor_forms_on_updated_at"
  end

  create_table "motor_note_tag_tags", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.bigint "tag_id", null: false
    t.index ["note_id", "tag_id"], name: "motor_note_tags_note_id_tag_id_index", unique: true
    t.index ["tag_id"], name: "index_motor_note_tag_tags_on_tag_id"
  end

  create_table "motor_note_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_note_tags_name_unique_index", unique: true
  end

  create_table "motor_notes", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "author_type"], name: "motor_notes_author_id_author_type_index"
    t.index ["record_id", "record_type"], name: "motor_notes_record_id_record_type_index"
  end

  create_table "motor_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.string "record_id"
    t.string "record_type"
    t.string "status", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "recipient_type"], name: "motor_notifications_recipient_id_recipient_type_index"
    t.index ["record_id", "record_type"], name: "motor_notifications_record_id_record_type_index"
  end

  create_table "motor_queries", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name", null: false
    t.text "preferences", null: false
    t.text "sql_body", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_queries_name_unique_index", unique: true, where: "(deleted_at IS NULL)"
    t.index ["updated_at"], name: "index_motor_queries_on_updated_at"
  end

  create_table "motor_reminders", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "author_type", null: false
    t.datetime "created_at", null: false
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.string "record_id"
    t.string "record_type"
    t.datetime "scheduled_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "author_type"], name: "motor_reminders_author_id_author_type_index"
    t.index ["recipient_id", "recipient_type"], name: "motor_reminders_recipient_id_recipient_type_index"
    t.index ["record_id", "record_type"], name: "motor_reminders_record_id_record_type_index"
    t.index ["scheduled_at"], name: "index_motor_reminders_on_scheduled_at"
  end

  create_table "motor_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "preferences", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_motor_resources_on_name", unique: true
    t.index ["updated_at"], name: "index_motor_resources_on_updated_at"
  end

  create_table "motor_taggable_tags", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "taggable_id", null: false
    t.string "taggable_type", null: false
    t.index ["tag_id"], name: "index_motor_taggable_tags_on_tag_id"
    t.index ["taggable_id", "taggable_type", "tag_id"], name: "motor_polymorphic_association_tag_index", unique: true
  end

  create_table "motor_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_tags_name_unique_index", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.string "owner_email", null: false
    t.string "phone"
    t.jsonb "settings", default: {}, null: false
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_organizations_on_discarded_at"
    t.index ["settings"], name: "index_organizations_on_settings", using: :gin
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["status"], name: "index_organizations_on_status"
  end

  create_table "raffle_prizes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "lottery_prize_position", null: false
    t.integer "position", null: false
    t.bigint "raffle_id", null: false
    t.datetime "updated_at", null: false
    t.index ["raffle_id", "position"], name: "index_raffle_prizes_on_raffle_id_and_position", unique: true
    t.index ["raffle_id"], name: "index_raffle_prizes_on_raffle_id"
  end

  create_table "raffles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.date "draw_date", null: false
    t.integer "draw_mode", null: false
    t.bigint "lottery_id", null: false
    t.bigint "organization_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "ticket_price", precision: 10, scale: 2, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_raffles_on_discarded_at"
    t.index ["draw_date"], name: "index_raffles_on_draw_date"
    t.index ["lottery_id"], name: "index_raffles_on_lottery_id"
    t.index ["organization_id"], name: "index_raffles_on_organization_id"
    t.index ["status"], name: "index_raffles_on_status"
  end

  create_table "tickets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "number", null: false
    t.string "payment_method"
    t.string "payment_reference"
    t.bigint "raffle_id", null: false
    t.datetime "reserved_until"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["discarded_at"], name: "index_tickets_on_discarded_at"
    t.index ["raffle_id", "number"], name: "index_tickets_on_raffle_id_and_number", unique: true
    t.index ["raffle_id"], name: "index_tickets_on_raffle_id"
    t.index ["reserved_until"], name: "index_tickets_on_reserved_until"
    t.index ["status"], name: "index_tickets_on_status"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", null: false
    t.string "name", null: false
    t.bigint "organization_id"
    t.string "password_digest", null: false
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "draws", "lottery_schedules"
  add_foreign_key "lottery_schedules", "lotteries"
  add_foreign_key "motor_alert_locks", "motor_alerts", column: "alert_id"
  add_foreign_key "motor_alerts", "motor_queries", column: "query_id"
  add_foreign_key "motor_note_tag_tags", "motor_note_tags", column: "tag_id"
  add_foreign_key "motor_note_tag_tags", "motor_notes", column: "note_id"
  add_foreign_key "motor_taggable_tags", "motor_tags", column: "tag_id"
  add_foreign_key "raffle_prizes", "raffles"
  add_foreign_key "raffles", "lotteries"
  add_foreign_key "raffles", "organizations"
  add_foreign_key "tickets", "raffles"
  add_foreign_key "tickets", "users"
  add_foreign_key "users", "organizations"
end
