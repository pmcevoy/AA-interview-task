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

### Stack (pick one — both equally acceptable)

- **Option A:** React frontend + C# / .NET 8 Web API backend
- **Option B:** Blazor Server (.NET 8) — single project, or Blazor + REST service

### Data

- **Database:** SQL Server localhost (LocalDB or containerised)
- **ORM:** Entity Framework Core (or Dapper — your choice)
- **Schema:** Applied via EF migrations or startup script — app must self-initialise on first run
- **Seed data:** A few mechanics, service types, and slots so the app is usable immediately

### Docker

- `docker-compose.yml` and any required `Dockerfile`s if Docker is used

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

## Key Decisions to Make Before Starting

| Decision | Options |
|---|---|
| Stack | Option A (React + .NET API) vs Option B (Blazor Server) |
| ORM | EF Core vs Dapper |
| DB setup | LocalDB vs containerised SQL Server |
| Auth stand-in | "Act as" user dropdown |
| Docker | Yes / No |

---

## Notes / Planning

> _Use this section to capture your own pre-build decisions and prompting strategy._

- **Stack chosen:**
- **Rationale:**
- **Initial prompt approach:**
- **Commit strategy:**
- **What I'll write by hand:**
