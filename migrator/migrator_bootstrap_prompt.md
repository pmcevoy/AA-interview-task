# Migrator Session — Bootstrap Prompt

## Context

I am building an SMR (Service, Maintenance & Repair) appointment scheduling application for a
coding interview. The full stack is three Docker Compose services: `db` (SQL Server 2022), 
`migrator` (this session), and `app` (Blazor Server .NET 8, separate session).

The `db` service is already running and verified healthy. Its healthcheck uses:

```
cat /var/opt/mssql/log/errorlog | grep -q 'SQL Server is now ready for client connections'
```

Read `CLAUDE.md` in this folder before doing anything else. It defines the full scope and
constraints for this session.

## Your Task

Produce two files in the `migrator/` folder:

1. `Dockerfile`
2. `run-migrations.sh`

## Key Constraints

- The migrator is **ephemeral** — it runs, applies migrations, and exits 0. It must not stay running.
- Migration scripts live in `../db/migrations/` and are **mounted** into the container at `/migrations/` — do not copy them into the image.
- The `db` service healthcheck is already defined in `docker-compose.yml`. The migrator service will use `depends_on: db: condition: service_healthy` — so **do not add a retry loop waiting for SQL Server** in the shell script; Docker handles that ordering guarantee.
- Scripts must be executed in strict ascending filename order (`001_...` before `002_...`).
- Fail-fast: if any script returns a non-zero exit code, stop immediately and exit non-zero.
- The scripts themselves are idempotent, so re-running the full set on container restart is safe.

## sqlcmd Path Issue

The Microsoft SQL tools image has changed the `sqlcmd` binary location in recent versions:
- Older: `/opt/mssql-tools/bin/sqlcmd`  
- Newer (mssql-tools18): `/opt/mssql-tools18/bin/sqlcmd`

Choose a base image and sqlcmd path that is consistent and reliable. Do not assume a path without
verifying it exists in the chosen image. Suggest which image you intend to use and why before
writing the Dockerfile.

## Environment Variables

The following will be passed in via `docker-compose.yml`:

| Variable | Purpose |
|---|---|
| `MIGRATOR_USER` | SQL Server login with DDL permissions |
| `MIGRATOR_PASSWORD` | Password for migrator login |
| `MSSQL_DB` | Target database name (`SmrScheduler`) |

The SQL Server hostname within the Docker network is `db`.

## What I Will Do After This Session

Once you produce the two files, I will:
1. Add the `migrator` service to `docker-compose.yml` with the correct `depends_on`, volume mount,
   and environment variables.
2. Run `docker compose up` and verify the migrator exits 0.
3. The migration scripts (`001_create_schema.sql`, `002_seed_data.sql`) do not exist yet — that is
   a separate session. For now the migrator just needs to handle an empty `migrations/` directory
   gracefully (exit 0 if no scripts found).

## Out of Scope

- The migration SQL scripts themselves
- The `docker-compose.yml` (I will update that manually)
- The Blazor application
