# Administration Guide

## Prerequisites

- Docker Desktop installed ([download](https://www.docker.com/products/docker-desktop/))
- Git installed
- A terminal (Terminal.app on Mac, PowerShell on Windows)

## Initial Setup

1. Clone the repository

```bash
git clone https://github.com/your-org/bah-workshop-tracker.git
cd bah-workshop-tracker
```

2. Create environment file

```bash
cp .env.example .env
```

Edit `.env` and fill in:
- `ADMIN_EMAIL` - Email for the initial admin account
- `ADMIN_PASSWORD` - Password for the initial admin account
- `ADMIN_DISPLAY_NAME` - Display name for the initial admin account (defaults to "Admin")
- `EXCHANGERATE_API_KEY` - Get a free key from [exchangerate-api.com](https://www.exchangerate-api.com/) (optional, FX features work without it but won't fetch rates)
- `SENDGRID_API_KEY` - Only needed if you want email delivery; in development, emails open in browser automatically
- `HONEYBADGER_API_KEY` - Error tracking in production (optional, get from [honeybadger.io](https://www.honeybadger.io/))
- `AR_ENCRYPTION_PRIMARY_KEY`, `AR_ENCRYPTION_DETERMINISTIC_KEY`, `AR_ENCRYPTION_KEY_DERIVATION_SALT` - Generate with `docker compose run --rm web bin/rails db:encryption:init`

3. Build and start

```bash
docker compose build
docker compose run --rm web bin/rails db:schema:load db:seed
docker compose up
```

4. Access the app

Open `http://localhost:3000` in your browser.

Log in with `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `.env`.

5. First steps after login

1. Go to Settings in the sidebar to verify config values (VAT rate, standard hours, tax rates)
2. Go to Users to create accounts for other team members
3. Go to Workers to add workshop workers
4. Go to Projects to create your first project

## Day-to-Day Operations

Starting the app

```bash
cd bah-workshop-tracker
docker compose up
```

Stopping the app

Press `Ctrl+C` in the terminal, or:

```bash
docker compose down
```

### Pagination

Lists with more than 50 rows (Workers, Users, Material entries, Currency rates) show pagination (50 per page); all entries remain accessible. The projects list and the project phase/task tree are never paginated—the tree is always fully expandable with all phases and tasks on one page.

## User Management

- Only admins can create users. Go to Users > New User.
- Assign roles: `admin`, `owner`, `manager`
- Users cannot self-register
- Admin can deactivate, soft-delete, or reset passwords for any user

## Roles

| Role | Planning | Daily Logs | Workers | Materials | Costs/Salary | Reports | Gantt | Config | FX Rates |
|---|---|---|---|---|---|---|---|---|---|
| Admin | Full CRUD | Full CRUD | Full CRUD | Full CRUD | Full access | Full access | View + Edit | Full CRUD | View + Fetch |
| Manager | Full CRUD | Full CRUD | Full CRUD | Full CRUD | Full access | Full access | View + Edit | Full CRUD | View + Fetch |
| Owner | View only | View only | View only (incl. salary) | View only | View only | View only | View only | View only | View only |

**Key points:**
- Admin and Manager have identical permissions (full CRUD across the board).
- Owner is strictly read-only — can view all data including reports, costs, and salary information, but cannot create, update, or delete any records.

## FX Rates

- Rates are fetched automatically once daily at 8:00 UTC (if `EXCHANGERATE_API_KEY` is set)
- Admin/Manager can manually fetch rates: go to FX Rates > Fetch Latest Rates
- If rates are missing for a date, a "No FX" badge appears next to GBP values

## Configuration

Go to Settings to manage:

| Key | Default | Description |
|---|---|---|
| `default_vat_rate` | 0.21 | Romanian VAT rate for materials (0% or 21%) |
| `standard_hours_per_day` | 8 | Standard working hours per day |
| `cas_rate` | 0.25 | Social insurance (CAS) rate |
| `cass_rate` | 0.10 | Health insurance (CASS) rate |
| `income_tax_rate` | 0.10 | Romanian income tax rate |
| `fx_api_provider` | exchangerate_api | FX provider identifier |

## Reports

Available to Admin, Owner, Manager:

- Labour by Project — Hours and cost per project, broken down by worker
- Labour by Worker — Hours and cost per worker, broken down by project
- Labour Summary — Total hours and cost per project
- Materials by Project — Material entries with VAT breakdown
- Combined Cost — Labour + materials per project

All reports support:
- Date range filtering
- Project/worker filtering
- XLSX and PDF export

## Backup

Development database backup:

```bash
docker compose exec db pg_dump -U postgres bah_workshop_development > backup_$(date +%Y%m%d).sql
```

Restore:

```bash
docker compose exec -T db psql -U postgres bah_workshop_development < backup_YYYYMMDD.sql
```

Production uses `bin/backup` which creates gzipped dumps with 30-day retention. Schedule it via cron on the server.

## Updating

```bash
git pull
docker compose build
docker compose run --rm web bin/rails db:migrate
docker compose up
```

### Upgrading from Foreman Role (Legacy)

If upgrading from a version that used the `foreman` role (role value 1), update existing users. The current enum values are: `admin: 0, owner: 1, manager: 2`.

Run these updates in order:

```sql
-- Step 1: Update old owner (2) -> new owner (1)
UPDATE users SET role = 1 WHERE role = 2;

-- Step 2: Update old manager (3) -> new manager (2)
UPDATE users SET role = 2 WHERE role = 3;

-- Step 3: Convert old foreman (1) users
-- Option A: Keep as owner (no change needed, foreman=1 is now owner=1)
-- Option B: Convert to manager
UPDATE users SET role = 2 WHERE role = 1;
```

After running the SQL updates, restart the application. Old foreman users (role=1) automatically become owner users since the enum value 1 now maps to owner.

## Troubleshooting

| Issue | Solution |
|---|---|
| "Port 3000 already in use" | Run `docker compose down` first, or change port in docker-compose.yml |
| Database connection error | Ensure `docker compose up db` is running and healthy |
| Port 5432 conflict | Local PostgreSQL using port 5432. Set `DATABASE_PORT=5433` in `.env` |
| Missing translation keys | Clear cache: `docker compose run --rm web bin/rails tmp:clear` |
| FX rates not updating | Check `EXCHANGERATE_API_KEY` in .env; check Solid Queue worker is running |
| Slow first load | Normal — Tailwind CSS compiles on first request in development |

## Production Deployment

Deployment uses [Kamal](https://kamal-deploy.org/) to a VPS.

### Prerequisites

1. A VPS with Docker installed (Ubuntu 22.04+ recommended)
2. A domain pointing to the VPS IP
3. A GHCR (GitHub Container Registry) account for Docker images
4. All environment variables set (see `.env.example`)

### First deploy

1. Generate secrets:
   - `SECRET_KEY_BASE`: `docker compose run --rm web bin/rails secret`
   - Encryption keys: `docker compose run --rm web bin/rails db:encryption:init`
2. Edit `config/deploy.yml` — fill in server IP, domain, and GitHub username
3. Set Kamal secrets (see `config/deploy.yml` for the full list)
4. Deploy: `kamal setup` (first time) or `kamal deploy` (subsequent)

Kamal handles SSL via Thruster (automatic Let's Encrypt), runs both web and Solid Queue worker processes, and provisions a PostgreSQL accessory container.

### Backups

Schedule `bin/backup` via cron on the server for daily PostgreSQL dumps with 30-day retention.

### Error tracking

Set `HONEYBADGER_API_KEY` to enable error and CSP violation reporting in production.

### Rate limiting

Rack::Attack is configured with:
- 300 requests / 5 minutes per IP (general)
- 10 login attempts / 15 minutes per IP and email
- 5 password reset requests / hour per IP
