# frozen_string_literal: true

# Baseline migration matching the schema as of 2026-02-14.
# For fresh databases, this creates all tables.
# For existing databases (dev/test), mark as applied: bin/rails db:migrate:status
class CreateInitialSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_catalog.plpgsql"

    create_table "active_storage_blobs", force: :cascade do |t|
      t.string "key", null: false
      t.string "filename", null: false
      t.string "content_type"
      t.text "metadata"
      t.string "service_name", null: false
      t.bigint "byte_size", null: false
      t.string "checksum"
      t.datetime "created_at", null: false
      t.index [ "key" ], name: "index_active_storage_blobs_on_key", unique: true
    end

    create_table "active_storage_attachments", force: :cascade do |t|
      t.string "name", null: false
      t.string "record_type", null: false
      t.bigint "record_id", null: false
      t.bigint "blob_id", null: false
      t.datetime "created_at", null: false
      t.index [ "blob_id" ], name: "index_active_storage_attachments_on_blob_id"
      t.index [ "record_type", "record_id", "name", "blob_id" ], name: "index_active_storage_attachments_uniqueness", unique: true
    end

    create_table "active_storage_variant_records", force: :cascade do |t|
      t.bigint "blob_id", null: false
      t.string "variation_digest", null: false
      t.index [ "blob_id", "variation_digest" ], name: "index_active_storage_variant_records_uniqueness", unique: true
    end

    create_table "audit_logs", force: :cascade do |t|
      t.string "action", null: false
      t.string "auditable_type", null: false
      t.bigint "auditable_id", null: false
      t.jsonb "changes_data", default: {}
      t.datetime "created_at", null: false
      t.string "ip_address"
      t.bigint "user_id"
      t.index [ "auditable_type", "auditable_id" ], name: "index_audit_logs_on_auditable"
      t.index [ "created_at" ], name: "index_audit_logs_on_created_at"
      t.index [ "user_id" ], name: "index_audit_logs_on_user_id"
    end

    create_table "attachments", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "discarded_at"
      t.string "file_name", null: false
      t.bigint "file_size"
      t.string "mime_type"
      t.bigint "related_id", null: false
      t.string "related_type", null: false
      t.string "storage_path"
      t.datetime "updated_at", null: false
      t.datetime "uploaded_at", null: false
      t.bigint "uploaded_by_user_id", null: false
      t.index [ "discarded_at" ], name: "index_attachments_on_discarded_at"
      t.index [ "related_type", "related_id" ], name: "index_attachments_on_related_type_and_related_id"
      t.index [ "uploaded_by_user_id" ], name: "index_attachments_on_uploaded_by_user_id"
    end

    create_table "configs", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.string "key", null: false
      t.datetime "updated_at", null: false
      t.text "value"
      t.index [ "key" ], name: "index_configs_on_key", unique: true
    end

    create_table "currency_rates", force: :cascade do |t|
      t.string "base_currency", default: "RON", null: false
      t.datetime "created_at", null: false
      t.date "date", null: false
      t.string "quote_currency", default: "GBP", null: false
      t.decimal "rate", precision: 16, scale: 8, null: false
      t.string "source"
      t.datetime "updated_at", null: false
      t.index [ "date", "base_currency", "quote_currency" ], name: "idx_currency_rates_unique_date_pair", unique: true
    end

    create_table "daily_logs", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.bigint "created_by_user_id", null: false
      t.datetime "discarded_at"
      t.decimal "hours_worked", precision: 5, scale: 2, default: "8.0", null: false
      t.date "log_date", null: false
      t.text "scope"
      t.bigint "project_id", null: false
      t.bigint "task_id", null: false
      t.datetime "updated_at", null: false
      t.bigint "worker_id", null: false
      t.index [ "created_by_user_id" ], name: "index_daily_logs_on_created_by_user_id"
      t.index [ "discarded_at" ], name: "index_daily_logs_on_discarded_at"
      t.index [ "log_date" ], name: "index_daily_logs_on_log_date"
      t.index [ "project_id", "task_id" ], name: "index_daily_logs_on_project_id_and_task_id"
      t.index [ "project_id" ], name: "index_daily_logs_on_project_id"
      t.index [ "task_id" ], name: "index_daily_logs_on_task_id"
      t.index [ "worker_id", "log_date" ], name: "index_daily_logs_on_worker_id_and_log_date"
      t.index [ "worker_id" ], name: "index_daily_logs_on_worker_id"
    end

    create_table "material_entries", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.bigint "created_by_user_id", null: false
      t.date "date", null: false
      t.string "description", null: false
      t.datetime "discarded_at"
      t.bigint "project_id", null: false
      t.decimal "quantity", precision: 12, scale: 4, null: false
      t.string "supplier_name"
      t.bigint "task_id"
      t.decimal "total_cost_ex_vat_ron", precision: 14, scale: 2, null: false
      t.decimal "total_cost_inc_vat_ron", precision: 14, scale: 2, null: false
      t.decimal "total_vat_ron", precision: 14, scale: 2, null: false
      t.string "unit", null: false
      t.decimal "unit_cost_ex_vat_ron", precision: 12, scale: 2, null: false
      t.decimal "unit_cost_inc_vat_ron", precision: 12, scale: 2, null: false
      t.datetime "updated_at", null: false
      t.decimal "vat_rate", precision: 5, scale: 4, default: "0.21", null: false
      t.index [ "created_by_user_id" ], name: "index_material_entries_on_created_by_user_id"
      t.index [ "discarded_at" ], name: "index_material_entries_on_discarded_at"
      t.index [ "project_id", "date" ], name: "index_material_entries_on_project_id_and_date"
      t.index [ "project_id" ], name: "index_material_entries_on_project_id"
      t.index [ "task_id" ], name: "index_material_entries_on_task_id"
    end

    create_table "password_histories", force: :cascade do |t|
      t.bigint "user_id", null: false
      t.string "password_digest", null: false
      t.datetime "created_at", null: false
      t.index [ "user_id" ], name: "index_password_histories_on_user_id"
    end

    create_table "phases", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.text "description"
      t.datetime "discarded_at"
      t.string "name", null: false
      t.date "planned_end_date", null: false
      t.date "planned_start_date", null: false
      t.integer "priority", default: 1, null: false
      t.bigint "project_id", null: false
      t.integer "status", default: 0, null: false
      t.datetime "updated_at", null: false
      t.index [ "discarded_at" ], name: "index_phases_on_discarded_at"
      t.index [ "planned_end_date" ], name: "index_phases_on_planned_end_date"
      t.index [ "planned_start_date" ], name: "index_phases_on_planned_start_date"
      t.index [ "project_id", "status" ], name: "index_phases_on_project_id_and_status"
      t.index [ "project_id" ], name: "index_phases_on_project_id"
    end

    create_table "projects", force: :cascade do |t|
      t.string "client_name"
      t.datetime "created_at", null: false
      t.bigint "created_by_user_id", null: false
      t.text "description"
      t.datetime "discarded_at"
      t.string "name", null: false
      t.date "planned_end_date", null: false
      t.date "planned_start_date", null: false
      t.integer "status", default: 0, null: false
      t.datetime "updated_at", null: false
      t.index [ "created_by_user_id" ], name: "index_projects_on_created_by_user_id"
      t.index [ "discarded_at" ], name: "index_projects_on_discarded_at"
      t.index [ "planned_end_date" ], name: "index_projects_on_planned_end_date"
      t.index [ "planned_start_date" ], name: "index_projects_on_planned_start_date"
      t.index [ "status" ], name: "index_projects_on_status"
    end

    create_table "sessions", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "expires_at"
      t.string "ip_address"
      t.datetime "updated_at", null: false
      t.string "user_agent"
      t.bigint "user_id", null: false
      t.index [ "expires_at" ], name: "index_sessions_on_expires_at"
      t.index [ "user_id" ], name: "index_sessions_on_user_id"
    end

    create_table "tasks", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.text "description"
      t.datetime "discarded_at"
      t.string "name", null: false
      t.bigint "phase_id"
      t.date "planned_end_date", null: false
      t.date "planned_start_date", null: false
      t.integer "priority", default: 1, null: false
      t.bigint "project_id", null: false
      t.integer "status", default: 0, null: false
      t.datetime "updated_at", null: false
      t.index [ "discarded_at" ], name: "index_tasks_on_discarded_at"
      t.index [ "phase_id" ], name: "index_tasks_on_phase_id"
      t.index [ "planned_end_date" ], name: "index_tasks_on_planned_end_date"
      t.index [ "planned_start_date" ], name: "index_tasks_on_planned_start_date"
      t.index [ "project_id", "status" ], name: "index_tasks_on_project_id_and_status"
      t.index [ "project_id" ], name: "index_tasks_on_project_id"
    end

    create_table "user_settings", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.integer "default_currency_display", default: 0, null: false
      t.jsonb "last_dashboard_filters", default: {}
      t.integer "last_gantt_zoom", default: 7, null: false
      t.datetime "updated_at", null: false
      t.bigint "user_id", null: false
      t.index [ "user_id" ], name: "index_user_settings_on_user_id", unique: true
    end

    create_table "users", force: :cascade do |t|
      t.boolean "active", default: true, null: false
      t.string "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "created_at", null: false
      t.datetime "discarded_at"
      t.string "display_name", null: false
      t.string "email_address", null: false
      t.string "password_digest", null: false
      t.integer "role", default: 0, null: false
      t.datetime "updated_at", null: false
      t.index [ "confirmation_token" ], name: "index_users_on_confirmation_token", unique: true
      t.index [ "discarded_at" ], name: "index_users_on_discarded_at"
      t.index [ "email_address" ], name: "index_users_on_email_address", unique: true
      t.index [ "role" ], name: "index_users_on_role"
    end

    create_table "worker_salaries", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.decimal "derived_daily_rate_ron", precision: 10, scale: 4, null: false
      t.datetime "discarded_at"
      t.date "effective_from", null: false
      t.decimal "gross_monthly_ron", precision: 12, scale: 2, null: false
      t.decimal "net_monthly_ron", precision: 12, scale: 2, null: false
      t.datetime "updated_at", null: false
      t.bigint "worker_id", null: false
      t.index [ "discarded_at" ], name: "index_worker_salaries_on_discarded_at"
      t.index [ "worker_id", "effective_from" ], name: "index_worker_salaries_on_worker_id_and_effective_from", unique: true
      t.index [ "worker_id" ], name: "index_worker_salaries_on_worker_id"
    end

    create_table "workers", force: :cascade do |t|
      t.boolean "active", default: true, null: false
      t.datetime "created_at", null: false
      t.datetime "discarded_at"
      t.string "full_name", null: false
      t.text "notes"
      t.string "trade"
      t.datetime "updated_at", null: false
      t.index [ "active" ], name: "index_workers_on_active"
      t.index [ "discarded_at" ], name: "index_workers_on_discarded_at"
    end

    add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
    add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
    add_foreign_key "attachments", "users", column: "uploaded_by_user_id"
    add_foreign_key "daily_logs", "projects"
    add_foreign_key "daily_logs", "tasks"
    add_foreign_key "daily_logs", "users", column: "created_by_user_id"
    add_foreign_key "daily_logs", "workers"
    add_foreign_key "material_entries", "projects"
    add_foreign_key "material_entries", "tasks", on_delete: :nullify
    add_foreign_key "material_entries", "users", column: "created_by_user_id"
    add_foreign_key "phases", "projects", name: "phases_project_id_fkey", on_delete: :restrict
    add_foreign_key "projects", "users", column: "created_by_user_id"
    add_foreign_key "sessions", "users"
    add_foreign_key "tasks", "phases", name: "tasks_phase_id_fkey", on_delete: :restrict
    add_foreign_key "tasks", "projects"
    add_foreign_key "user_settings", "users"
    add_foreign_key "audit_logs", "users", on_delete: :nullify
    add_foreign_key "password_histories", "users"
    add_foreign_key "worker_salaries", "workers"
  end
end
