# AA Coding Interview Task — SMR Appointment Scheduler

## Overview

Build a small internal scheduling application for the AA's Service, Maintenance & Repair (SMR) team.
The goal is to replace spreadsheets and shared calendars, which cause double-bookings, missed jobs,
and lost notes between mechanics.

**Time budget:** No more than 3 hours before the interview.  
**AI usage:** Expected and encouraged — Claude Code, Cursor, Codex, or similar.  
**Repo:** Public Git repository (GitHub / GitLab), shared before the interview.  
**Commits:** Several small, descriptive commits preferred over one large "initial commit".  
**Prompts:** Save initial and follow-up prompts; note where context drifted and how you corrected it.

---

## Functional Requirements

### Customer / Booking-Agent Flow

- View available appointment slots for the next 7 days
- Filter slots by service type (Inspection, Service, Repair, Diagnostics)
- Book an appointment by providing:
  - Customer name
  - Customer phone number
  - Vehicle registration
  - Service type
  - Branch / location (multi-branch support required)
  - Notes / description of issue
- Prevent double-booking of the same slot
- Show booking confirmation with a unique reference number

### Mechanic Flow

- View appointments assigned to them for today and tomorrow
- Open an appointment to see customer details, vehicle info, and customer notes
- Add timestamped work notes to an appointment (free text)
- Update appointment status: `Scheduled → In Progress → Completed` (or `No-Show`)

### Admin / Shared

- Home page showing today's schedule across all mechanics

---

## Out of Scope (note as future work if approached)

- Authentication / login — a "act as" user dropdown is fine
- Email or SMS notifications
- Rescheduling and cancellation flows
- Recurring appointments
- Payments / invoicing
- Mobile-specific UI

---

## Technical Requirements

### Stack — **Option B: Blazor Server (.NET 8)**

Chosen over React + Web API to stay entirely within C#/.NET — no JavaScript context-switching. Blazor Server's SignalR connection also gives natural real-time slot availability without polling.  A single application project serving UI and API.

### Data Access — **Dapper**

Chosen over EF Core deliberately. Dapper keeps SQL visible and explicit; no ORM magic obscuring what hits the database. Aligns with the view that "fat" ORMs are appropriate to hide from developers, not architects.

### Database — **Containerised SQL Server**

Consistent, reproducible, no LocalDB quirks. One `docker compose up` runs everything.

### Schema Management — **Plain versioned `.sql` scripts, run idempotently**

No migration framework (DbUp, Flyway, etc.). Scripts are numbered sequentially:

```
db/migrations/
  001_create_schema.sql
  002_seed_data.sql
```

All DDL uses `IF NOT EXISTS` guards. All seed data uses `IF NOT EXISTS` / `MERGE` so scripts are safe to re-run on container restart. An entrypoint wrapper script on the SQL Server container executes them in order on first boot.

**Rationale:** In a production context a DBA needs to read, review, and potentially optimise these scripts before they touch a production server. Plain SQL with no tooling dependency is the only format that works universally — for a pipeline, for a DBA, and for a container init. The idempotency guards mean a pipeline re-run or container restart won't break anything.

### Docker

Three services in `docker-compose.yml`:

| Service | Purpose |
|---|---|
| `db` | SQL Server container |
| `migrator` | Entrypoint script runs numbered `.sql` files via `sqlcmd`; exits when done |
| `app` | Blazor Server; `depends_on: migrator` |

---

## Source Control

- Public Git repo
- Meaningful, incremental commit history (not a single "initial commit")

---

## Deliverables

### In the Git Repo

- Application source code
- `docker-compose.yml` / `Dockerfile`(s) if applicable
- `README.md` (brief — 1–2 lines each section) covering:
  - How to run it (ideally one command)
  - Stack choice and rationale
  - What's done, what's not done, what would be next with more time
  - Any known bugs or rough edges
  - Which AI tool(s) were used
  - What planning was done upfront
  - Prompts used (optional but encouraged)
  - Anything deliberately written by hand rather than AI-generated

---

## During the Interview

- Walk through the codebase — high-level architecture, then specific decisions
- Discuss AI usage — show a prompt or two from the session
- Make a small live change (an extension will be given); AI use is expected and welcome here too

---

## Decisions Summary

| Decision | Chosen | Rationale |
|---|---|---|
| Stack | Blazor Server (.NET 8) | Stay in C#/.NET end to end; no JS; SignalR suits real-time slot updates |
| Data access | Dapper | Explicit SQL; no ORM abstraction hiding database behaviour |
| Database | Containerised SQL Server | Consistent, reproducible, no LocalDB quirks |
| Schema management | Plain versioned `.sql` scripts | DBA-readable, no tooling dependency, idempotent with `IF NOT EXISTS` guards |
| Auth stand-in | "Act as" user dropdown | Per spec — out of scope for real auth |
| Docker | Yes — three services | `db`, `migrator`, `app` |

---

## Notes / Planning

- **Commit strategy:** Small, descriptive commits per logical unit — schema, models, booking flow, mechanic flow, admin view, docker setup, README
- **What to write by hand:** SQL migration scripts (DBA-quality, reviewed carefully); docker-compose.yml structure
- **What to delegate to Claude Code:** Blazor component scaffolding, Dapper repository boilerplate, service layer wiring, seed data population
- **Out of scope to note in README:** Auth, notifications, rescheduling/cancellation, recurring appointments, payments, mobile UI
