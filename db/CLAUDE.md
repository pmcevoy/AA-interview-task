# CLAUDE.md — `db/` — SQL Server Container & Schema Migrations

## Purpose of This Folder

This folder owns everything related to the database container and schema lifecycle:

- The SQL Server Docker image configuration
- The `entrypoint.sh` wrapper that waits for SQL Server to be ready
- All numbered migration scripts under `migrations/`

This is **not** the migration runner. The migrator service (in `../migrator/`) connects to this
container and executes the scripts. This folder is purely the database host and the SQL artefacts.

---

## Context — What You're Building

This is the `db` service in a three-container Docker Compose stack for an SMR (Service, Maintenance
& Repair) appointment scheduling application. The other two services are:

- `migrator` — connects to this container, runs the migration scripts, then exits
- `app` — a Blazor Server (.NET 8) application that connects for DML only

The `app` service does **not** start until the migrator exits successfully.

---

## Docker Image

Base image: `mcr.microsoft.com/mssql/server:2022-latest`

The `Dockerfile` here overrides the entrypoint with `entrypoint.sh`, which:

1. Starts SQL Server in the background (`/opt/mssql/bin/sqlservr &`)
2. Polls `sqlcmd` until the server accepts connections (retry loop, ~2s sleep)
3. Signals readiness — the migrator's `depends_on: db` health check triggers from here
4. Keeps the container running (`wait` on the background process)

The SA password and other config come from environment variables set in `docker-compose.yml`.

---

## Migration Scripts

Location: `migrations/`  
Naming: `NNN_description.sql` (e.g. `001_create_schema.sql`, `002_seed_data.sql`)  
Executed by: the `migrator` service, in filename order, via `sqlcmd`

### Idempotency Rules — Non-Negotiable

Every script must be safe to re-run without error or side effect:

- All `CREATE TABLE` statements wrapped in `IF NOT EXISTS` (or `IF OBJECT_ID(...) IS NULL`)
- All `CREATE INDEX` statements likewise guarded
- All `ALTER TABLE` (adding columns, constraints) guarded with existence checks
- Seed data inserted via `MERGE` on a natural key, **not** bare `INSERT` — prevents duplicate rows on re-run
- No `DROP` statements unless wrapped in an existence check and explicitly required

### Script: `001_create_schema.sql`

Creates the database if it doesn't exist, then creates all tables and constraints.

**Entities to create:**

- `Branch` — Id, Name, Address
- `ServiceType` — Id, Name, DurationMinutes
- `Mechanic` — Id, Name, BranchId (FK → Branch)
- `AppointmentSlot` — Id, BranchId, MechanicId, ServiceTypeId, StartTime, EndTime, IsAvailable (BIT)
- `Appointment` — Id, SlotId (FK → AppointmentSlot, **UNIQUE constraint**), ReferenceNumber (UNIQUE),
  CustomerName, CustomerPhone, VehicleReg, ServiceTypeId (FK), Notes, Status (NVARCHAR — values:
  Scheduled, InProgress, Completed, NoShow), CreatedAt (DATETIME2)
- `WorkNote` — Id, AppointmentId (FK → Appointment), NoteText (NVARCHAR(MAX)), CreatedAt (DATETIME2)

**Critical constraint:** `Appointment.SlotId` must have a `UNIQUE` constraint. This is the hard
guard against double-booking — the application layer also checks, but the database is the final
arbiter.

**Two database users to create:**

- `smr_migrator` — DDL permissions (used by the migrator service only)
- `smr_app` — DML only: `SELECT`, `INSERT`, `UPDATE`, `DELETE` on all tables (used by the Blazor app)

### Script: `002_seed_data.sql`

Populates reference and test data so the application is usable on first run.

**Seed the following:**

- 2–3 Branches (e.g. Dublin, Cork, Galway)
- 4 ServiceTypes: Inspection, Service, Repair, Diagnostics (with representative DurationMinutes)
- 3–4 Mechanics distributed across branches
- AppointmentSlots: generate slots for each mechanic covering the next 7 days, working hours
  09:00–17:00, in increments matching each ServiceType's duration. All seeded with `IsAvailable = 1`

Use `MERGE` for all seed inserts, matching on natural keys (e.g. Branch.Name, ServiceType.Name,
Mechanic.Name) so re-runs are safe.

---

## Environment Variables (set via docker-compose.yml)

| Variable | Purpose |
|---|---|
| `ACCEPT_EULA` | Must be `Y` |
| `SA_PASSWORD` | SA password for initial setup |
| `MSSQL_DB` | Database name to create (e.g. `SmrScheduler`) |
| `MIGRATOR_USER` | Username for the migrator DB user |
| `MIGRATOR_PASSWORD` | Password for the migrator DB user |
| `APP_USER` | Username for the app DB user |
| `APP_PASSWORD` | Password for the app DB user |

---

## What This Session Should Produce

- `db/Dockerfile`
- `db/entrypoint.sh`
- `db/migrations/001_create_schema.sql`
- `db/migrations/002_seed_data.sql`

---

## Out of Scope for This Session

- The migration runner logic (that's `migrator/`)
- The `docker-compose.yml` at the repo root (that's the `infra` concern)
- Application code (that's `app/`)
