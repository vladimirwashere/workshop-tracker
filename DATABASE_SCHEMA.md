# Database Schema

PostgreSQL 16. All timestamps stored as UTC. All monetary values stored in RON.

## Tables

### users

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| email_address | string | NOT NULL, UNIQUE | Login email |
| password_digest | string | NOT NULL | bcrypt hash |
| role | integer | NOT NULL, default: 0 | 0=admin, 1=owner, 2=manager |
| active | boolean | NOT NULL, default: true | Account active flag |
| display_name | string | NOT NULL | User's display name |
| confirmed_at | datetime | | Email confirmation timestamp |
| confirmation_token | string | UNIQUE | Email confirmation token |
| discarded_at | datetime | | Soft delete (Discard) |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: `email_address` (unique), `role`, `discarded_at`, `confirmation_token` (unique)

### sessions

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK(users) | |
| ip_address | string | | Client IP |
| user_agent | string | | Browser user agent |
| expires_at | datetime | | Session expiry timestamp |
| created_at / updated_at | datetime | NOT NULL | |

### user_settings

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK(users), UNIQUE | 1:1 with users |
| default_currency_display | integer | NOT NULL, default: 0 | 0=RON, 1=GBP |
| last_gantt_zoom | integer | NOT NULL, default: 7 | Gantt period preset: 7, 14, 30, 90, 180, 365 days |
| last_dashboard_filters | jsonb | default: {} | Persisted filter state |
| created_at / updated_at | datetime | NOT NULL | |

### workers

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| full_name | string | NOT NULL | |
| trade | string | | e.g. "Carpenter" |
| active | boolean | NOT NULL, default: true | |
| notes | text | | |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: `active`, `discarded_at`

### worker_salaries

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| worker_id | bigint | NOT NULL, FK(workers) | |
| gross_monthly_ron | decimal(12,2) | NOT NULL | Gross salary |
| net_monthly_ron | decimal(12,2) | NOT NULL | Auto-calculated from gross |
| derived_daily_rate_ron | decimal(10,4) | NOT NULL | gross * 12 / 52 / 5 |
| effective_from | date | NOT NULL | Salary effective date |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: (`worker_id`, `effective_from`) UNIQUE, `discarded_at`

Business rules: `net_monthly_ron` calculated using CAS (25%), CASS (10%), income tax (10%) from Config. `derived_daily_rate_ron = gross_monthly_ron * 12 / 52 / 5`.

### projects

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| name | string | NOT NULL | |
| client_name | string | | Optional client |
| status | integer | NOT NULL, default: 0 | 0=planned, 1=active, 2=completed, 3=on_hold, 4=cancelled |
| planned_start_date | date | NOT NULL | |
| planned_end_date | date | NOT NULL | |
| description | text | | |
| created_by_user_id | bigint | NOT NULL, FK(users) | |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: `status`, `planned_start_date`, `planned_end_date`, `created_by_user_id`, `discarded_at`

Business rules: Cannot be `completed` unless all tasks are `done` or `cancelled`. End date must be >= start date.

### phases

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| project_id | bigint | NOT NULL, FK(projects) | |
| name | string | NOT NULL | |
| description | text | | |
| planned_start_date | date | NOT NULL | |
| planned_end_date | date | NOT NULL | |
| status | integer | NOT NULL, default: 0 | 0=planned, 1=in_progress, 2=done, 3=cancelled |
| priority | integer | NOT NULL, default: 1 | 0=low, 1=medium, 2=high |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: (`project_id`, `status`), `planned_start_date`, `planned_end_date`, `discarded_at`

Business rules: Phase dates must fall within project date range. End date >= start date.

### tasks

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| project_id | bigint | NOT NULL, FK(projects) | |
| phase_id | bigint | FK(phases) | Optional; task may belong to a phase |
| name | string | NOT NULL | |
| description | text | | |
| planned_start_date | date | NOT NULL | |
| planned_end_date | date | NOT NULL | |
| status | integer | NOT NULL, default: 0 | 0=planned, 1=in_progress, 2=done, 3=cancelled |
| priority | integer | NOT NULL, default: 1 | 0=low, 1=medium, 2=high |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: (`project_id`, `status`), `phase_id`, `planned_start_date`, `planned_end_date`, `discarded_at`

Business rules: Task dates must fall within project date range. If `phase_id` is present, task dates must also fall within phase date range. End date >= start date.

### daily_logs

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| project_id | bigint | NOT NULL, FK(projects) | |
| task_id | bigint | NOT NULL, FK(tasks) | |
| worker_id | bigint | NOT NULL, FK(workers) | |
| log_date | date | NOT NULL | |
| hours_worked | decimal(5,2) | NOT NULL, default: 8.0 | |
| scope | text | | Work description |
| created_by_user_id | bigint | NOT NULL, FK(users) | |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: `log_date`, (`project_id`, `task_id`), (`worker_id`, `log_date`), `discarded_at`

Business rules: Labour cost allocated via daily rate per worker-day. Daily rate resolved from the latest `WorkerSalary` where `effective_from <= log_date`. When a worker has multiple log entries on the same day, the daily rate is split proportionally across entries.

### material_entries

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| project_id | bigint | NOT NULL, FK(projects) | |
| task_id | bigint | FK(tasks) | Optional |
| date | date | NOT NULL | |
| description | string | NOT NULL | Free text |
| quantity | decimal(12,4) | NOT NULL | |
| unit | string | NOT NULL | e.g. "pcs", "m", "sheet" |
| unit_cost_ex_vat_ron | decimal(12,2) | NOT NULL | |
| unit_cost_inc_vat_ron | decimal(12,2) | NOT NULL | Unit cost including VAT |
| vat_rate | decimal(5,4) | NOT NULL, default: 0.21 | Allowed: 0 (0%) or 0.21 (21%) |
| total_cost_ex_vat_ron | decimal(14,2) | NOT NULL | qty * unit_cost |
| total_vat_ron | decimal(14,2) | NOT NULL | total_ex * vat_rate |
| total_cost_inc_vat_ron | decimal(14,2) | NOT NULL | total_ex + total_vat |
| supplier_name | string | | |
| created_by_user_id | bigint | NOT NULL, FK(users) | |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: (`project_id`, `date`), `discarded_at`

### attachments

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| related_type | string | NOT NULL | DailyLog, MaterialEntry, Task |
| related_id | bigint | NOT NULL | Polymorphic FK |
| file_name | string | NOT NULL | Original filename |
| file_size | bigint | | Bytes (synced from Active Storage blob) |
| mime_type | string | | Content type (synced from Active Storage blob) |
| storage_path | string | | Legacy field (files stored via Active Storage) |
| uploaded_by_user_id | bigint | NOT NULL, FK(users) | |
| uploaded_at | datetime | NOT NULL | |
| discarded_at | datetime | | Soft delete |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: (`related_type`, `related_id`), `discarded_at`

Business rules: Files stored via Active Storage (`has_one_attached :file`). Max file size 25 MB. Allowed types: images (JPEG, PNG, GIF, WebP, HEIC, HEIF, TIFF, CR2, NEF, ARW, DNG, RW2, ORF, RAF), documents (PDF, DOC, DOCX, XLS, XLSX, CSV, TXT, Markdown), CAD (DWG). Thumbnail variants generated for JPEG, PNG, GIF, WebP only.

### active_storage_blobs

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| key | string | NOT NULL, UNIQUE | Storage key |
| filename | string | NOT NULL | Original filename |
| content_type | string | | MIME type |
| metadata | text | | JSON metadata |
| service_name | string | NOT NULL | Storage service (local, test) |
| byte_size | bigint | NOT NULL | File size in bytes |
| checksum | string | | MD5 checksum |
| created_at | datetime | NOT NULL | |

### active_storage_attachments

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| name | string | NOT NULL | Attachment name (e.g. "file") |
| record_type | string | NOT NULL | Polymorphic model name |
| record_id | bigint | NOT NULL | Polymorphic record ID |
| blob_id | bigint | NOT NULL, FK(active_storage_blobs) | |
| created_at | datetime | NOT NULL | |

Indexes: (`record_type`, `record_id`, `name`, `blob_id`) UNIQUE

### active_storage_variant_records

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| blob_id | bigint | NOT NULL, FK(active_storage_blobs) | |
| variation_digest | string | NOT NULL | Variant parameters digest |

Indexes: (`blob_id`, `variation_digest`) UNIQUE

### currency_rates

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| date | date | NOT NULL | |
| base_currency | string | NOT NULL, default: "RON" | |
| quote_currency | string | NOT NULL, default: "GBP" | |
| rate | decimal(16,8) | NOT NULL | RON per 1 GBP |
| source | string | | e.g. "exchangerate_api" |
| created_at / updated_at | datetime | NOT NULL | |

Indexes: (`date`, `base_currency`, `quote_currency`) UNIQUE

### configs

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| key | string | NOT NULL, UNIQUE | Config key |
| value | text | | String/JSON value |
| created_at / updated_at | datetime | NOT NULL | |

Default keys: `default_vat_rate` (0.21), `standard_hours_per_day` (8), `cas_rate` (0.25), `cass_rate` (0.10), `income_tax_rate` (0.10), `fx_api_provider`

### audit_logs

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| action | string | NOT NULL | create, update, discard |
| auditable_type | string | NOT NULL | Polymorphic model name |
| auditable_id | bigint | NOT NULL | Polymorphic record ID |
| changes_data | jsonb | default: {} | Attribute changes snapshot |
| user_id | bigint | FK(users), ON DELETE NULLIFY | Acting user |
| ip_address | string | | Client IP at time of action |
| created_at | datetime | NOT NULL | |

Indexes: (`auditable_type`, `auditable_id`), `created_at`, `user_id`

Immutable — records are never updated or deleted. `user_id` is nullified if the user is deleted.

### password_histories

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK(users) | |
| password_digest | string | NOT NULL | bcrypt hash of previous password |
| created_at | datetime | NOT NULL | |

Indexes: `user_id`

Stores the last 5 password digests per user. Used to prevent password reuse.

## Relationships

```
User 1---* Session
User 1---1 UserSetting
User 1---* Project (created_by)
User 1---* DailyLog (created_by)
User 1---* MaterialEntry (created_by)
User 1---* Attachment (uploaded_by)
User 1---* AuditLog
User 1---* PasswordHistory

Worker 1---* WorkerSalary
Worker 1---* DailyLog

Project 1---* Phase
Project 1---* Task
Project 1---* DailyLog
Project 1---* MaterialEntry

Phase 1---* Task

Task ---optional--- Phase
Task 1---* DailyLog

Attachment ---polymorphic--- Task|DailyLog|MaterialEntry
Attachment 1---1 ActiveStorageBlob (via ActiveStorageAttachment)
```

## Soft Deletes

All main entities use Discard (`discarded_at` column). Soft-deleted records are hidden from normal queries but preserved for historical data integrity. Tables with soft delete: users, workers, worker_salaries, projects, phases, tasks, daily_logs, material_entries, attachments.
