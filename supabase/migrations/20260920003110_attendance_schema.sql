-- CRS Ops — attendance schema (Phase 3)

create schema if not exists attendance;

create table attendance.shift_defaults (
  id uuid primary key default gen_random_uuid(),
  effective_from date not null,
  default_start time not null,
  default_end time not null,
  week_off_days smallint[] not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (effective_from)
);

-- Seeded at 2000-01-01, NOT "today" — every shift_defaults lookup picks the row
-- with the largest effective_from <= the date being evaluated. A launch-dated
-- seed row would leave every future-imported historical date with zero matching
-- rows, breaking effective_range_status/derived_flags on exactly the data being
-- migrated in later.
insert into attendance.shift_defaults (effective_from, default_start, default_end, week_off_days)
values ('2000-01-01', '10:30', '18:30', '{7}');

create table attendance.status_types (
  id text primary key,
  label text not null,
  icon_name text,
  color_hex text,
  description text
);

insert into attendance.status_types (id, label, icon_name, color_hex) values
  ('present', 'Present', 'check', '#4CAF50'),
  ('absent', 'Absent', 'close', '#F44336'),
  ('leave', 'Leave', 'event_busy', '#FF9800'),
  ('holiday', 'Holiday', 'beach_access', '#2196F3'),
  ('week_off', 'Week Off', 'weekend', '#9E9E9E');

alter table attendance.shift_defaults enable row level security;
create policy shift_defaults_select on attendance.shift_defaults
  for select using (auth.role() = 'authenticated');
create policy shift_defaults_insert on attendance.shift_defaults
  for insert with check (core.is_admin_or_above());
-- No update/delete policy at all: this table is deliberately append-only, per
-- the design (a shift-hours change inserts a new row, never edits an old one).

alter table attendance.status_types enable row level security;
create policy status_types_select on attendance.status_types
  for select using (auth.role() = 'authenticated');
create policy status_types_insert on attendance.status_types
  for insert with check (core.is_admin_or_above());
create policy status_types_update on attendance.status_types
  for update using (core.is_admin_or_above()) with check (core.is_admin_or_above());
