# AA SMR Appointment Scheduler — Architecture Overview

## Repository Structure

```
aa-smr-scheduler/
│
├── docker-compose.yml              # Orchestrates all three services
├── README.md                       # Per-spec deliverable
├── ARCHITECTURE.md                 # This document
│
├── db/                             # Database service — own CLAUDE.md
│   ├── CLAUDE.md
│   ├── Dockerfile                  # SQL Server + entrypoint wrapper
│   ├── entrypoint.sh               # Waits for SQL Server ready, runs migrations in order
│   └── migrations/
│       ├── 001_create_schema.sql
│       └── 002_seed_data.sql
│
├── migrator/                       # Migration runner service — own CLAUDE.md
│   ├── CLAUDE.md
│   ├── Dockerfile                  # Minimal image: sqlcmd + scripts
│   └── run-migrations.sh           # Iterates migrations/ in order, exits 0 on success
│
└── app/                            # Blazor Server application — own CLAUDE.md
    ├── CLAUDE.md
    ├── Dockerfile
    ├── SmrScheduler.sln
    └── SmrScheduler/
        ├── Program.cs
        ├── appsettings.json
        ├── Data/
        │   ├── IAppointmentRepository.cs
        │   ├── AppointmentRepository.cs
        │   ├── ISlotRepository.cs
        │   ├── SlotRepository.cs
        │   ├── IMechanicRepository.cs
        │   └── MechanicRepository.cs
        ├── Models/
        │   ├── Appointment.cs
        │   ├── AppointmentSlot.cs
        │   ├── Mechanic.cs
        │   ├── Branch.cs
        │   ├── ServiceType.cs
        │   └── WorkNote.cs
        ├── Services/
        │   ├── IBookingService.cs
        │   └── BookingService.cs
        └── Components/
            ├── Layout/
            │   └── MainLayout.razor
            ├── Pages/
            │   ├── Home.razor              # Admin: today's schedule across all mechanics
            │   ├── BookAppointment.razor   # Booking-agent flow
            │   ├── MechanicView.razor      # Mechanic: today + tomorrow appointments
            │   └── AppointmentDetail.razor # Mechanic: detail, work notes, status update
            └── Shared/
                └── UserContext.razor       # "Act as" dropdown — auth stand-in
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
Branch
  Id              INT PK
  Name            NVARCHAR
  Address         NVARCHAR

ServiceType
  Id              INT PK
  Name            NVARCHAR        -- Inspection | Service | Repair | Diagnostics
  DurationMinutes INT

Mechanic
  Id              INT PK
  Name            NVARCHAR
  BranchId        INT FK → Branch

AppointmentSlot
  Id              INT PK
  BranchId        INT FK → Branch
  MechanicId      INT FK → Mechanic
  ServiceTypeId   INT FK → ServiceType
  StartTime       DATETIME2
  EndTime         DATETIME2
  IsAvailable     BIT             -- flipped to 0 on booking

Appointment
  Id              INT PK
  ReferenceNumber NVARCHAR        -- unique, generated on insert (e.g. SMR-YYYYMMDD-XXXX)
  SlotId          INT FK → AppointmentSlot (UNIQUE constraint — enforces no double-booking)
  CustomerName    NVARCHAR
  CustomerPhone   NVARCHAR
  VehicleReg      NVARCHAR
  ServiceTypeId   INT FK → ServiceType
  Notes           NVARCHAR(MAX)
  Status          NVARCHAR        -- Scheduled | InProgress | Completed | NoShow
  CreatedAt       DATETIME2

WorkNote
  Id              INT PK
  AppointmentId   INT FK → Appointment
  NoteText        NVARCHAR(MAX)
  CreatedAt       DATETIME2       -- timestamped on insert
```

**Double-booking prevention:** A `UNIQUE` constraint on `Appointment.SlotId` is the hard guard.
`AppointmentSlot.IsAvailable` is a soft indicator used by the UI to filter the available slots list.
Both are updated within the same transaction on booking.

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

---

## Key Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Frontend | Blazor Server (.NET 8), single project | Stay in C# end-to-end; SignalR gives real-time updates without polling; no separate API needed at this scale |
| Data access | Dapper | SQL stays explicit and visible; no ORM abstraction; DBA-friendly |
| Database | Containerised SQL Server 2022 | Consistent across environments; no LocalDB quirks; fully self-contained |
| Schema management | Plain versioned `.sql` files, idempotent | DBA-readable with no tooling dependency; safe to re-run; pipeline-compatible |
| App DB permissions | DML only | DDL is the migrator's concern, not the application's |
| Double-booking | DB UNIQUE constraint + soft IsAvailable flag | Constraint is the hard guard; flag drives UI filtering |
| Auth stand-in | "Act as" user dropdown | Per spec; real auth is explicitly out of scope |
