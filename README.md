# BAH Workshop Tracker

Workshop project planning, daily work logging, cost tracking, and reporting application for BAH Projects Ltd. Manages furniture production operations in Romania with dual-currency support (RON/GBP).

## Stack

| Layer | Technology |
|-------|------------|
| Core | Ruby 3.3.6, Rails 8.1.2, PostgreSQL 16 |
| Frontend | Tailwind CSS 4, Hotwire (Turbo + Stimulus), D3.js |
| Auth | Pundit (deny-by-default), bcrypt, Active Record Encryption |
| Background | Solid Queue |
| Libraries | Discard (soft deletes), Pagy (pagination), Prawn (PDF), caxlsx (XLSX) |
| Ops | Honeybadger (error tracking), Rack::Attack (rate limiting) |
| Testing | Minitest + FactoryBot |
| Infrastructure | Docker Compose, Kamal, GitHub Actions CI/CD |

## Architecture

### Models

- **User** — Role-based access (admin:0, owner:1, manager:2) with encrypted email, password history
- **Project** — Core entity with optional Phases
- **Phase** — Optional grouping within Projects
- **Task** — Belongs to Project, optionally to Phase
- **Worker** — Employee management with salary history
- **WorkerSalary** — Gross/net salary with derived daily rate
- **DailyLog** — Time tracking with `scope` field for work descriptions
- **MaterialEntry** — Material costs with VAT support (0% or 21%)
- **CurrencyRate** — RON/GBP exchange rate tracking
- **Attachment** — Polymorphic file attachments via Active Storage (25MB limit)
- **AuditLog** — Immutable mutation log with user attribution and IP
- **PasswordHistory** — Password reuse prevention (last 5 passwords)
- **Config** — Key-value application configuration
- **Session** — Time-bounded user sessions with IP tracking
- **UserSetting** — Per-user preferences (currency, Gantt zoom, dashboard filters)

### Concerns

**Model:** `Auditable` (audit logging on create/update/discard), `DateRangeValidatable` (date range validations), `Attachable` (polymorphic attachments), `Statusable` (status enum with transitions), `CreatedByUser` (creator tracking)

**Policy:** `StandardCrudPolicy` (DRY CRUD authorization rules)

**Controller:** `Authentication` (session management), `CreatesAttachmentsFromParams` (file upload handling)

### Services

| Service | Purpose |
|---------|----------|
| `FXFetcher` | ExchangeRate-API integration with retry/backoff |
| `ReportGenerator` | Unified report data (labour, materials, combined) |
| `XlsxExporter` | Excel export for all report types |
| `PdfExporter` | PDF generation with Prawn |
| `CurrencyConverter` | RON/GBP conversion using stored rates |

### Authorization

Role-based access control via Pundit:
- **Admin & Manager**: Identical permissions, full CRUD across all resources
- **Owner**: Read-only access to all data including reports, costs, and salary information
- All policies inherit `ApplicationPolicy` with deny-by-default security model

### Background Jobs

| Job | Schedule | Purpose |
|-----|----------|----------|
| `FetchFXRatesJob` | Daily 8:00 UTC | Fetch RON/GBP exchange rate |
| `CleanupExpiredSessionsJob` | Daily 3:00 UTC | Remove expired sessions |

Processed via Solid Queue (`config/recurring.yml`).

## Quick Start

### Prerequisites

- Docker Desktop installed
- Git installed

### Setup

```bash
# Clone the repository
git clone https://github.com/your-org/bah-workshop-tracker.git
cd bah-workshop-tracker

# Create environment file
cp .env.example .env
# Edit .env — set ADMIN_EMAIL, ADMIN_PASSWORD, and AR_ENCRYPTION_* keys
# Generate encryption keys: bin/rails db:encryption:init

# Build and initialize
docker compose build
docker compose run --rm web bin/rails db:schema:load db:seed

# Start services
docker compose up
```

Visit `http://localhost:3000` and log in with `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `.env`.

See `admin_instructions.md` for detailed setup and configuration guide.

## Development

### Running Tests

```bash
docker compose run --rm web bin/rails test
```

### Background Jobs

The `worker` service handles Solid Queue jobs (FX rate fetching). It starts automatically with `docker compose up`.

### Schema Changes

Schema changes use Rails migrations:

```bash
docker compose run --rm web bin/rails generate migration AddColumnToTable column:type
docker compose run --rm web bin/rails db:migrate
```

### CI/CD Pipeline

Automated via `.github/workflows/ci.yml`:
1. **Security** — Gitleaks secret scanning
2. **Lint** — RuboCop, Brakeman, bundler-audit, importmap audit
3. **Test** — Full test suite with PostgreSQL
4. **Build** — Docker image verification

## Environment Variables

See `.env.example` for detailed inline comments. Key variables:

### Database (Required)
| Variable | Description |
|----------|-------------|
| `DATABASE_HOST` | PostgreSQL host (default: `db` for Docker) |
| `DATABASE_USERNAME` | Database username (default: `postgres`) |
| `DATABASE_PASSWORD` | Database password |
| `DATABASE_PORT` | Host port for DB container (default: 5432) |

### Rails (Required in Production)
| Variable | Description |
|----------|-------------|
| `SECRET_KEY_BASE` | Rails secret key for sessions/cookies. Generate with `bin/rails secret` |
| `RAILS_ENV` | Environment (development/production) |

### Email (Optional)
| Variable | Description |
|----------|-------------|
| `SENDGRID_API_KEY` | SendGrid API key for transactional emails. Optional; dev mode opens emails in browser |
| `MAILER_FROM` | From address for emails |
| `MAILER_DOMAIN` | Domain for email delivery |

### FX Rates (Optional)
| Variable | Description |
|----------|-------------|
| `EXCHANGERATE_API_KEY` | API key from exchangerate-api.com. Optional; FX features work without it but won't fetch rates |

### Active Record Encryption (Required)
| Variable | Description |
|----------|-------------|
| `AR_ENCRYPTION_PRIMARY_KEY` | Primary encryption key. Generate with `bin/rails db:encryption:init` |
| `AR_ENCRYPTION_DETERMINISTIC_KEY` | Deterministic encryption key |
| `AR_ENCRYPTION_KEY_DERIVATION_SALT` | Key derivation salt |

| `HONEYBADGER_API_KEY` | No | Error tracking (reports in production only) |

### Application (Required)
| Variable | Description |
|----------|-------------|
| `APP_HOST` | App hostname for email links and absolute URLs (e.g., `localhost:3000` or `app.example.com`) |

### Admin Seed Account (Required on First Setup)
| Variable | Description |
|----------|-------------|
| `ADMIN_EMAIL` | Email for the initial admin account |
| `ADMIN_PASSWORD` | Password for the initial admin account |
| `ADMIN_DISPLAY_NAME` | Display name for the initial admin account (defaults to "Admin") |

## Key Features

### Project & Task Planning
- Hierarchical project structure with optional phases
- Task assignment with planned hours
- Interactive Gantt chart visualization (D3.js) with drag-and-drop date editing
- Full project tree view (always expandable, never paginated)

### Daily Work Logging
- Line-by-line time tracking with worker assignment
- Duplicate shortcut for repetitive entries
- Scope field for work descriptions
- Date range filtering with period shortcuts

### Worker Management
- Employee profiles with trade/specialty
- Salary history tracking with automatic hourly rate calculation
- Worker timeline visualization showing assignments and actual hours
- Romanian tax calculations (CAS 25%, CASS 10%, income tax 10%)

### Cost Tracking
- **Labour Costs**: Auto-calculated from worker salary history
- **Material Costs**: Entry-level tracking with VAT support (0% or 21%)
- **Currency Support**: Dual-currency display (RON/GBP) with automatic conversion
- **FX Integration**: Daily exchange rate fetching with missing rate indicators

### Unified Reporting System
- **Labour Reports**: By project, by worker, or summary view
- **Materials Report**: Project-level breakdown with VAT details
- **Combined Cost Report**: Labour + materials per project
- **Export Options**: Excel (XLSX) and PDF for all report types
- Date range and project/worker filtering

### Dashboard & Analytics
- KPI cards: Total labour, materials, combined costs, hours logged
- Top 5 active projects summary
- Date range filtering with persistence

### File Attachments
- Polymorphic attachment support for tasks, daily logs, and material entries
- 25MB file size limit
- Lightbox image viewer
- Active Storage integration

### Security & Audit
- Active Record Encryption for PII (email addresses)
- Password complexity requirements and reuse prevention (last 5)
- Time-bounded sessions with concurrent session limits
- Audit logging on all data mutations with user attribution
- Content Security Policy, SSL enforcement, CSRF protection
- HTTP-only cookies with SameSite=Lax
- See `SECURITY.md` for full security policy

## Deployment

Deployable to any Docker-capable PaaS (Render, Fly.io, Railway) or self-hosted with Kamal.

- **Dockerfile** — Multi-stage production build with jemalloc, Thruster (port 80)
- **Kamal** — Config included (`config/deploy.yml`)
- All environment variables must be set (see `.env.example`)
- Solid Queue worker must be running for background jobs

## Documentation

| File | Description |
|------|-------------|
| `README.md` | Project overview and quick start |
| `admin_instructions.md` | Setup, configuration, and operations guide |
| `DATABASE_SCHEMA.md` | Database schema reference |
| `SECURITY.md` | Security policy and vulnerability reporting |
| `CLAUDE.md` | AI assistant context and conventions |

## License

Internal use only.
