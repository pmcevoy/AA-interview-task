# AA SMR Appointment Scheduler — Architecture Overview

## Repository Structure

```
aa-smr-scheduler/
├── docker-compose.yml
├── README.md
├── ARCHITECTURE.md
├── db/                 # SQL Server container, migration scripts — own CLAUDE.md
├── migrator/           # Migration runner container — own CLAUDE.md
└── app/                # Blazor Server application — own CLAUDE.md
```

---

## Services Overview

### `db` — SQL Server Container

The SQL Server instance. Uses the standard `mcr.microsoft.com/mssql/server:2022-latest` image. An
`entrypoint.sh` wrapper starts SQL Server in the background, waits for it to be ready (polling
`sqlcmd`), then hands off to the migrator service via Docker `depends_on` ordering.

The database user available to the application is granted **DML permissions only** (`SELECT`,
`INSERT`, `UPDATE`, `DELETE`). DDL is executed exclusively by the migrator at startup.

### `migrator` — Migration Runner Container

A minimal container whose sole job is to apply schema migrations and then exit. It iterates the
`db/migrations/` directory in filename order, executing each `.sql` file via `sqlcmd`. All scripts
are idempotent — DDL uses `IF NOT EXISTS` guards, seed data uses `MERGE` on natural keys — so
re-running on container restart is safe.

The migrator exits with code `0` on success. The `app` service is declared `depends_on: migrator`
with `condition: service_completed_successfully`, so the Blazor app will not start until migrations
have applied cleanly.

### `app` — Blazor Server (.NET 8)

Single-project Blazor Server application. UI and data access run in the same process; there is no
separate REST API layer — Blazor Server's server-side model makes this unnecessary at this scale.

Data access is via **Dapper** with explicit SQL queries. No ORM. Repositories are interface-backed
for testability. A thin `BookingService` encapsulates the double-booking prevention logic (using a
database-level unique constraint as the ultimate guard, with an optimistic check before attempting
insert).

---

## Data Model

```
┌─────────┐        ┌─────────────┐        ┌──────────────────┐
│ Branch  │        │  Mechanic   │        │  ServiceType     │
├─────────┤        ├─────────────┤        ├──────────────────┤
│ Id      │◄───────│ BranchId    │        │ Id               │
│ Name    │        │ Id          │        │ Name             │
│ Address │        │ Name        │        │ DurationMinutes  │
└─────────┘        └──────┬──────┘        └────────┬─────────┘
     │                    │                         │
     │                    │                         │
     │             ┌──────▼──────────────────────────▼─────┐
     └────────────►│            AppointmentSlot            │
                   ├───────────────────────────────────────┤
                   │ Id                                    │
                   │ BranchId                              │
                   │ MechanicId                            │
                   │ ServiceTypeId                         │
                   │ StartTime / EndTime                   │
                   │ IsAvailable  ← soft UI filter         │
                   └──────────────────┬────────────────────┘
                                      │ UNIQUE constraint
                                      │ (hard double-booking guard)
                   ┌──────────────────▼─────────────────────┐
                   │              Appointment               │
                   ├────────────────────────────────────────┤
                   │ Id                                     │
                   │ SlotId                                 │
                   │ ReferenceNumber  ← unique, generated   │
                   │ CustomerName                           │
                   │ CustomerPhone                          │
                   │ VehicleReg                             │
                   │ ServiceTypeId                          │
                   │ Notes                                  │
                   │ Status  ← Scheduled|InProgress|        │
                   │           Completed|NoShow             │
                   │ CreatedAt                              │
                   └──────────────────┬─────────────────────┘
                                      │
                   ┌──────────────────▼─────────────────────┐
                   │               WorkNote                 │
                   ├────────────────────────────────────────┤
                   │ Id                                     │
                   │ AppointmentId                          │
                   │ NoteText                               │
                   │ CreatedAt  ← timestamped on insert     │
                   └────────────────────────────────────────┘
```

**Double-booking prevention:** The `UNIQUE` constraint on `Appointment.SlotId` is the hard guard —
the database will reject a duplicate regardless of application-layer timing. `AppointmentSlot.IsAvailable`
is a soft indicator used by the UI to filter the available slots list. Both are updated within the
same transaction on booking.

---

## User Flows

### Booking-Agent Flow

1. Select a branch and service type — slots are filtered by both
2. Available slots for the next 7 days are listed (where `IsAvailable = 1`)
3. Agent selects a slot, fills in customer name, phone, vehicle reg, and notes
4. On submit: slot marked unavailable, appointment row inserted, reference number returned
5. Confirmation screen shows reference number

### Mechanic Flow

1. "Act as" dropdown selects the active mechanic
2. List view shows appointments for today and tomorrow assigned to that mechanic
3. Clicking an appointment opens the detail view: customer info, vehicle, customer notes, work notes
4. Mechanic can add a timestamped work note (free text)
5. Status can be advanced: `Scheduled → In Progress → Completed` (or set to `No-Show`)

### Admin / Home

1. Home page (`/`) shows today's full schedule across all mechanics at all branches
2. Grouped by mechanic; shows appointment time, customer name, vehicle reg, service type, and status

---

## Docker Compose — Service Dependencies

```
db ──────────────────► (healthy / ready)
                              │
                              ▼
                         migrator ──► exits 0
                              │
                              ▼
                             app
```

`docker compose up` is the single command to start the full stack.

---

## Explicit Out of Scope

The following are not implemented. They are noted here as future work:

- Authentication and authorisation (replaced by "act as" dropdown)
- Email / SMS notifications on booking or status change
- Rescheduling and cancellation flows
- Recurring appointments
- Payments and invoicing
- Mobile-optimised UI

---

## Claude Code Session Boundaries

Each subfolder has its own `CLAUDE.md` and is intended to be worked in a separate Claude Code
session to keep context focused and token usage efficient.

| Folder | Claude Code Session Scope |
|---|---|
| `db/` | SQL schema design, migration scripts, seed data, entrypoint wrapper, Dockerfile |
| `migrator/` | Migration runner script, Dockerfile, dependency ordering |
| `app/` | Blazor Server project — models, repositories, services, Razor components, Dockerfile |

The `app/` session may be further subdivided if context grows — suggested split points are the
repository/data layer vs. the Blazor component layer.


