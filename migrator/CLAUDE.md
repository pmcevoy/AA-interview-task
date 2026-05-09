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

1. Waits for SQL Server to accept connections (retry loop against `db:1433`)
2. Iterates `migrations/` in strict filename order (`001_...`, `002_...`, etc.)
3. Executes each `.sql` file via `sqlcmd` using the migrator credentials
4. Exits `0` on success, non-zero on any failure

The migration scripts themselves live in `../db/migrations/`. Mount that directory into this
container — do not copy the scripts into this image. This keeps a single source of truth.

---

## Migration Runner Script (`run-migrations.sh`)

Shell script that:

```
for f in $(ls /migrations/*.sql | sort); do
    sqlcmd -S db -U $MIGRATOR_USER -P $MIGRATOR_PASSWORD -d $MSSQL_DB -i "$f"
    if [ $? -ne 0 ]; then
        echo "Migration failed: $f"
        exit 1
    fi
    echo "Applied: $f"
done
exit 0
```

Key points:
- `sort` ensures numeric filename order is respected
- Fail-fast: any script failure stops the run and exits non-zero
- Scripts are idempotent (enforced in `db/`), so re-running the full set is safe

---

## Environment Variables (from docker-compose.yml)

| Variable | Purpose |
|---|---|
| `MIGRATOR_USER` | DB username with DDL permissions |
| `MIGRATOR_PASSWORD` | Password for migrator user |
| `MSSQL_DB` | Target database name |

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
