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

ActiveRecord::Schema[8.0].define(version: 2024_12_11_125804) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "announcement_reads", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.bigint "contact_id", null: false
    t.datetime "read_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id", "contact_id"], name: "index_announcement_reads_on_announcement_id_and_contact_id", unique: true
    t.index ["announcement_id"], name: "index_announcement_reads_on_announcement_id"
    t.index ["contact_id"], name: "index_announcement_reads_on_contact_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.string "title", null: false
    t.text "preview"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "published_at", null: false
    t.index ["published_at"], name: "index_announcements_on_published_at"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "external_id", null: false
    t.jsonb "info_payload", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "segments_payload", default: {}
    t.index ["external_id"], name: "index_contacts_on_external_id", unique: true
  end

  create_table "contacts_segment_values", id: false, force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.bigint "segment_value_id", null: false
    t.index ["contact_id", "segment_value_id"], name: "idx_on_contact_id_segment_value_id_3cca80f7ec", unique: true
  end

  create_table "segment_values", force: :cascade do |t|
    t.bigint "segment_id", null: false
    t.string "val"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["segment_id"], name: "index_segment_values_on_segment_id"
  end

  create_table "segments", force: :cascade do |t|
    t.string "identifier", null: false
    t.boolean "allow_new_values", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_segments_on_identifier", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "status", default: 0
    t.integer "classification", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcement_reads", "announcements", on_delete: :cascade
  add_foreign_key "announcement_reads", "contacts", on_delete: :cascade
  add_foreign_key "segment_values", "segments", on_delete: :cascade
  add_foreign_key "sessions", "users"
end
