# CLAUDE.md — `app/` — Blazor Server Application

## Purpose of This Folder

This folder is the Blazor Server (.NET 8) application — the entire UI and data access layer in a
single project. There is no separate REST API; Blazor Server's server-side model makes that
unnecessary at this scale.

---

## Context — What You're Building

Part of a three-container Docker Compose stack for the AA SMR (Service, Maintenance & Repair)
appointment scheduling system. By the time this container starts, the database is up and all
migrations have been applied. This service connects for DML only — it has no DDL permissions.

The application serves three distinct user flows, toggled by an "Act as" dropdown (no real auth):

- **Booking Agent** — searches available slots and books appointments for customers
- **Mechanic** — views their own schedule, updates appointment status, adds work notes
- **Admin** — views today's full schedule across all mechanics (home page)

---

## Technology Choices

- **Blazor Server (.NET 8)** — single project, no JS, server-side rendering via SignalR
- **Dapper** — all data access via explicit SQL; no EF Core; no ORM magic
- **SQL Server** — connection string from environment variable; host is `db` (Docker service name)
- **Interface-backed repositories** — one interface + implementation per aggregate root

---

## Data Model (for reference — tables already exist in the database)

The database schema is owned by `db/migrations/`. Do not generate migrations or DDL here.

Entities the app works with:

- `Branch` — Id, Name, Address
- `ServiceType` — Id, Name, DurationMinutes
- `Mechanic` — Id, Name, BranchId
- `AppointmentSlot` — Id, BranchId, MechanicId, ServiceTypeId, StartTime, EndTime, IsAvailable
- `Appointment` — Id, SlotId (UNIQUE FK), ReferenceNumber, CustomerName, CustomerPhone,
  VehicleReg, ServiceTypeId, Notes, Status, CreatedAt
- `WorkNote` — Id, AppointmentId, NoteText, CreatedAt

Status values: `Scheduled`, `InProgress`, `Completed`, `NoShow`

---

## Project Structure Convention

Follow standard Blazor Server conventions:

- `Data/` — repository interfaces and implementations (Dapper, explicit SQL)
- `Models/` — plain C# model classes matching the DB schema (no EF annotations)
- `Services/` — `BookingService` encapsulating booking logic
- `Components/Pages/` — one Razor component per page/flow
- `Components/Shared/` — shared components (user context dropdown, etc.)

---

## Repository Layer

One interface + implementation per aggregate:

- `ISlotRepository` / `SlotRepository` — query available slots with filters
- `IAppointmentRepository` / `AppointmentRepository` — insert appointments, fetch by mechanic/date, update status
- `IMechanicRepository` / `MechanicRepository` — list mechanics (for dropdown and admin view)
- `IWorkNoteRepository` / `WorkNoteRepository` — insert and fetch work notes

All Dapper queries use parameterised SQL. No string concatenation in queries.

---

## Booking Service

`BookingService` / `IBookingService` encapsulates the booking transaction:

1. Check slot is still available (`IsAvailable = 1`) — optimistic read
2. Insert the `Appointment` row with a generated `ReferenceNumber`
3. Set `AppointmentSlot.IsAvailable = 0`
4. Steps 2 and 3 execute within a single `IDbTransaction`
5. If the `UNIQUE` constraint on `Appointment.SlotId` fires (race condition), catch the SQL
   exception and return a user-facing "slot no longer available" result — do not surface raw exceptions

Reference number format: `SMR-{YYYYMMDD}-{4-digit zero-padded sequential or random}` — unique per booking.

---

## Pages / Components

### Home (`/`) — Admin View
- Today's appointments across all mechanics at all branches
- Grouped by mechanic, ordered by start time
- Columns: Time, Customer Name, Vehicle Reg, Service Type, Status

### Book Appointment (`/book`) — Booking-Agent Flow
1. "Act as" dropdown (if not already set) — select branch context
2. Filter: Branch, Service Type
3. List of available slots for the next 7 days matching the filter
4. Select a slot → form: Customer Name, Phone, Vehicle Reg, Notes (Service Type pre-filled)
5. Submit → confirmation with Reference Number
6. Prevent double-booking: slot row disappears from list once taken; DB constraint is final guard

### Mechanic View (`/mechanic`) — Mechanic Flow
- "Act as" dropdown to select active mechanic
- Two sections: Today's appointments, Tomorrow's appointments
- Each row shows: Time, Customer Name, Vehicle Reg, Service Type, Status
- Click row → Appointment Detail

### Appointment Detail (`/appointment/{id}`) — Mechanic Flow
- Customer details, vehicle reg, service type, customer notes
- Current status with update control: advance through `Scheduled → InProgress → Completed` or set `NoShow`
- Work notes list (timestamped, newest last or first — your choice, be consistent)
- Add work note: free-text area + submit

---

## User Context ("Act as" Dropdown)

No real authentication. A shared component renders a dropdown of all mechanics plus an "Admin /
Agent" option. The selection is stored in a Blazor cascading parameter or scoped service for the
session. The Mechanic Flow pages require a mechanic to be selected; they should prompt if not set.

---

## Environment Variables

| Variable | Purpose |
|---|---|
| `ConnectionStrings__SmrScheduler` | Full SQL Server connection string |

Connection string format:
`Server=db,1433;Database=SmrScheduler;User Id=smr_app;Password=<AA_TASK_APP_PASSWORD>;TrustServerCertificate=True`

`AA_TASK_APP_PASSWORD` is an OS environment variable and should be passed via the docker-compose

---

## What This Session Should Produce

- `app/SmrScheduler.sln`
- `app/SmrScheduler/` — full Blazor Server project
- `app/Dockerfile`

Build the project in this order to keep commits logical:

1. Project scaffold + Dockerfile + connection wiring
2. Models + repository interfaces
3. Repository implementations (Dapper SQL)
4. BookingService
5. Home page (admin view — simplest, good smoke test)
6. Mechanic view + appointment detail
7. Book appointment flow

Commit after each step.

---

## Out of Scope for This Session

- SQL schema or migrations (owned by `db/`)
- `docker-compose.yml` (repo root)
- Authentication / login — the "Act as" dropdown is the full extent of user identity
- Email / SMS notifications
- Rescheduling or cancellation
- Recurring appointments
- Payments
- Mobile-specific UI
