# CLAUDE.md — `migrator/` — Migration Runner

## Purpose of This Folder

This folder owns the migration runner container. Its sole responsibility is to connect to the SQL
Server container, execute the numbered migration scripts from `../db/migrations/` in order, and
exit cleanly. It is ephemeral — it runs once per `docker compose up`, does its job, and stops.

---

## Context — What You're Building

This is the `migrator` service in a three-container Docker Compose stack:

- `db` — SQL Server container; must be healthy before this service runs
- `migrator` — this service; runs migrations then exits 0
- `app` — Blazor Server; waits for this service to complete successfully before starting

The `app` service uses `depends_on: migrator` with `condition: service_completed_successfully`.
A non-zero exit from this container will prevent the app from starting.

---

## Container Design

Minimal image — no application runtime needed, just `sqlcmd`.

Base image: `mcr.microsoft.com/mssql-tools` (provides `sqlcmd` without the full SQL Server)

The container:

1. Iterates `/migrations/*.sql` in strict filename order (`001_...`, `002_...`, etc.)
2. Executes each file via `sqlcmd` as `sa` — no dedicated migrator login is needed
3. Exits `0` on success, non-zero on any failure (sqlcmd `-b` flag enforces this)

The migration scripts themselves live in `../db/migrations/`. Mount that directory into this
container — do not copy the scripts into this image. This keeps a single source of truth.

No retry loop is needed: Docker's `depends_on: condition: service_healthy` guarantees the `db`
container is ready before this container starts.

---

## Migration Runner Script (`run-migrations.sh`)

- Before running any files: create the `smr_app` server login via `sqlcmd -Q` if it doesn't exist,
  using `AA_TASK_APP_PASSWORD` via bash interpolation — avoids sqlcmd `-v` scripting variables
- Glob `/migrations/*.sql` with `nullglob` — exits 0 cleanly if the directory is empty
- For each file in sorted glob order: run `sqlcmd -S db -U sa -b -i "$f"`
- Fail-fast on any non-zero exit; print the failing filename

---

## Environment Variables (from docker-compose.yml)

| Variable | Purpose |
|---|---|
| `AA_TASK_MSSQL_SA_PASSWORD` | SA password — used to connect to SQL Server |
| `AA_TASK_APP_PASSWORD` | Passed through to SQL scripts as `$(AA_TASK_APP_PASSWORD)` |

The SQL Server hostname is `db` (the Docker Compose service name).

---

## What This Session Should Produce

- `migrator/Dockerfile`
- `migrator/run-migrations.sh`

---

## Out of Scope for This Session

- The migration scripts themselves (those live in `db/migrations/`)
- The `docker-compose.yml` at the repo root
- Application code
