# CRS Ops — Project Brief

Context handoff doc, written from a conversation in a different project
(`crs_attendance`, the old Firebase-based attendance app). Continuing here
in a fresh Claude session.

## What this is

A new Flutter app for Chirag's dad's business. Working name: **CRS Ops**
(open to better names). Sibling to an existing app, **CRS Manager**
(handles delivery challans) — not a replacement, not touching that
codebase.

Long-term idea is a unified app covering both delivery/challan tracking
and employee/attendance tracking. For now, scope is **attendance module
only**. Challan stays exactly as-is until further notice.

## Why a new app instead of extending existing ones

- **CRS Manager** (challan app): old, schema/code disliked by the dev,
  but stable and business-critical. Not being touched. It currently has
  no real `employees` concept — deliveries have a free-text "delivered
  by" field that *usually* contains an employee name but isn't a real
  foreign key.
- **crs_attendance** (old attendance app): a working Flutter + Firebase
  app that does basic attendance tracking, but its data model is too
  thin for what's actually needed now (see Requirements below), and a
  security review of it turned up a real bug (see Lessons below).

Rather than retrofit either, this is a clean start.

## Stack decisions (already made, not open questions)

- **Flutter**, targeting **Android + Web + Desktop** (multi-platform from
  day one, not bolted on later).
- **Supabase**, not Firebase. Reasoning:
  - The new requirements (employee history/timeline, time logs) are
    inherently relational — Postgres + real FKs fits this far better
    than Firestore's document model. The old app had to hack around
    Firestore's limited range-query support (client-side re-filtering
    after a query) for date-range reports.
  - Postgres Row-Level Security is more explicit/auditable than Firestore
    security rules — directly motivated by a bug found in the old app
    (see Lessons).
  - **CRS Manager already uses Supabase + Flutter.** Building the new app
    on the same backend tech (even in a separate project) keeps the door
    open for an eventual real merge without a backend rewrite too.
- **Separate Supabase project** from CRS Manager, deliberately — not
  sharing a project/database yet. A migration to unify data (e.g. giving
  CRS Manager's "delivered by" field a real FK into a shared `employees`
  table) is an explicit **someday, not now** task.

## Requirements from stakeholder (Chirag's dad)

1. **Proper employee tracking**, beyond a simple active/inactive flag:
   - Join date, end date, current employment status
   - Needs to handle **rehires** — someone can leave and come back later
   - General desire for an employee "timeline" — not just rehire dates
     specifically, but a history of things that happened (join, leave,
     rehire, and whatever else comes up later — promotions, notes, etc.)
2. **Time logs**, not just a daily status:
   - Track actual start/end time worked per day
   - **Optional** — if not specified, default to **10:30–18:30 (8 hours)**
   - Should still support the simpler "just mark present/absent/half-day/
     leave" flow for days where exact times don't matter

## Data model direction (discussed, not finalized)

- Employee history as an **append-only event log**, not fixed columns:
  a table like `employee_events (employee_id, event_type, date, note)`
  where `event_type` is open-ended (`joined`, `left`, `rehired`, and
  whatever else gets added later). An employee's "current status" is a
  derived read (latest relevant event), not a separately maintained flag
  that can drift out of sync.
- Attendance/time-log records likely still keyed per employee per day,
  similar shape to the old app (status + optional time-in/time-out +
  remarks), but backed by proper Postgres tables/FKs instead of
  Firestore documents with string-based references.
- None of this is final — actual schema design is a next step in this
  new session.

## Lessons carried over from the old attendance app (crs_attendance)

From reviewing that codebase in the prior conversation:

- **Security**: its Firestore rules had a privilege-escalation hole — the
  `admins` collection's write rule allowed any authenticated user to
  self-grant admin status (`allow write: if request.auth.uid == adminId`
  with no check that the doc already existed / was granted by an actual
  admin). Whatever gates "admin"/role access in the new app, make sure
  the role-granting table/mechanism can never be self-service-writable
  by a normal authenticated user. Worth designing RLS policies for this
  explicitly rather than by default-allow patterns.
- **Performance**: several screens re-fetched the same collection
  redundantly instead of sharing cached state (e.g. a calendar view
  re-fetching the entire employee list on every month navigation, a
  detail page opening its own duplicate realtime listener instead of
  reusing an already-watched one). Worth keeping data-fetching
  centralized/cached from the start rather than letting each screen roll
  its own fetch.
- **Employee status modeling**: a single `disabled: bool` on the employee
  record turned out to be insufficient once rehire history mattered —
  reinforces the event-log approach above over boolean/flag fields.

## Open questions for this session

- Finalize the app name (currently: CRS Ops)
- Actual Supabase schema (tables, columns, RLS policies)
- Auth approach (Google sign-in like the old app, via Supabase Auth?)
- Feature scope for v1 — likely comparable feature set to the old app
  (mark attendance, manage employees, reports) but built on the new
  model, plus the new time-log/timeline requirements
- How/when "delivered by" in CRS Manager eventually links to this app's
  `employees` table (not blocking v1)
