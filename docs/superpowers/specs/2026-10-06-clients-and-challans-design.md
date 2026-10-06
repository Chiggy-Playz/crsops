# Clients and Challans — design

Date: 2026-10-06. Status: approved in conversation, section by section.

## Goal

Bring the delivery-challan workflow from the legacy `~/Projects/crs_manager`
app into CRS Ops at **feature parity**, on a clean data model. Assets are out
of scope (they come later from `~/Projects/asset_manager`). Permissions beyond
"module access" are deferred.

Facts below marked *(data)* come from the legacy production dump analysed on
2026-10-06: 1,516 outward challans, 59 inward, 181 buyers, 2,083 items.

## Data model

### `core` — clients are shared, like employees

```
core.indian_states            code text PK ('07'), name                 -- seeded
core.clients                  id uuid, name (unique, case-insensitive), notes,
                              archived_at, created_at, created_by
core.client_addresses         id uuid, client_id, label (internal, never printed),
                              archived_at, created_at
core.client_address_versions  id uuid, address_id, version int, name_on_challan,
                              address, state_code → indian_states, gstin (nullable),
                              created_at, created_by
                              UNIQUE (address_id, version)
core.current_client_addresses view: each address joined to its highest version
```

- One client, many addresses (branches/sites). *(data)* ~16 legacy companies
  encoded their branch in the name, e.g. "OFFSHOOT AGENCY (SECTOR 4)".
- **Address versioning.** A challan points at an address *version*. Saving an
  address edits the current version in place if no challan uses it, otherwise
  adds version + 1. A trigger makes used versions immutable. *(data)* edits are
  rare: 186 buyer names → 194 versions.
- `name_on_challan` lives on the version so reprinting an old challan prints
  exactly what it printed then, even after a client rename.
- GSTIN: 15-character format check only. **No check that its state code
  matches `state_code`** — *(data)* 8 buyers legitimately (or mistakenly)
  differ; "state" most likely means where the goods go. The form shows a
  dismissible warning on mismatch.
- Legacy `alias` (really "referred by" notes) imports into `clients.notes`.
- No contact, phone or pincode fields for now.

### `challans` schema

```
challans.challans
  id uuid, direction ('outward'|'inward'), financial_year smallint (2026 = FY 26-27),
  number int, challan_date date,
  client_address_version_id → core.client_address_versions,
  handled_by_name text (always printed), handled_by_employee_id (optional),
  vehicle_number?, declared_value? (whole rupees), notes?,
  outward only (CHECK null/false on inward): bill_number?, received_on?, digitally_signed,
  cancelled_at?, cancelled_by?, cancel_reason?,
  reverses_challan_id? (on an inward challan created by cancelling an outward one),
  created_at, created_by, updated_at
  UNIQUE (direction, financial_year, number)

challans.challan_items   id, challan_id, position, description, additional_description?,
                         serial?, quantity int > 0, unit?
challans.challan_events  append-only: challan_id, event_type, changes jsonb, note, created_by, created_at
```

- One table for both directions; numbering is separate per (direction, FY).
- Next number = `max(number) + 1` under `pg_advisory_xact_lock` keyed on
  (direction, FY). No counter table. Challans are never deleted; cancelled ones
  keep their number.
- Date rules (enforced in the create function): never in the future.
  **Outward:** on or after the latest outward challan in that FY.
  **Inward:** any date within the FY *(data: inward entries are routinely made
  weeks late)*. Direction, FY, number and date are immutable after save.
- Unit is optional *(data: 97% empty)*; quantity is a whole number > 0.

### Writes go only through functions

The app has SELECT only on these tables; every write is a `security definer`
function that checks access, runs in one transaction and logs an event.

- Clients: `create_client`, `update_client`, `set_client_archived`,
  `save_client_address`, `set_client_address_archived`.
- Challans: `create_challan`, `update_challan` (refused once cancelled; keeps
  the address version unless the user picks "use latest address details"),
  `cancel_challan(reason?, create_return default false)`, `set_received(date?)`,
  `set_bill_number(text?)`, `set_digitally_signed(bool)`.
- Validation failures raise with a user-facing message (SQLSTATE P0001), which
  the app shows as-is.

## Flutter structure

```
lib/core/clients/      section, routes, models, repositories, providers,
                       pages (split layout, list, detail, edit, address edit),
                       widgets (client address picker, GSTIN field)
lib/modules/challans/  section, routes, models, repositories, providers,
                       pages (split layout, list w/ Outward|Inward, detail, edit),
                       widgets (item editor, cancel dialog, client challans panel),
                       pdf (challan_pdf: Challan → bytes, letterhead constants, amount in words)
```

- `AppSection` gains `clientPanels` (title, canSee, builder(clientId)), so the
  client detail page shows challans without core importing the module.
- `ModuleNames.challans`; nav order: attendance, challans, clients, employees, settings.
- Clients is visible to anyone with challans access (for now).

## Lists, search, exports, PDF

- Challan list per direction, newest first, paged; quick search; FY /
  cancelled / not-received filters.
- Search runs server-side (`search_challans`: clients, date range, text,
  direction), results grouped by client. Exports (xlsx via `excel`): Detailed
  and Index, same columns as legacy.
- PDF: a faithful port of the legacy layout, copy labels included
  ("Original for Recipient / Duplicate for Supplier / Triplicate for
  Transporter", 1–3 copies or unlabelled, CANCELLED stamp). Additions only:
  items continue onto further pages, a font with ₹, an inward variant
  ("INWARD CHALLAN", "Received by", no bill number). Packages: `pdf`, `printing`.
  Letterhead and terms are Dart constants.

## Deferred

Photos of signed copies *(data: never used)*, permissions, the legacy import
(decided when we get to it; `received` → `received_on` = challan date with a
history note).

## Phases

1. Clients. 2. Outward challans + PDF + client panel. 3. Inward, cancel with
return, follow-ups, history timeline. 4. Search + exports. 5. Legacy import.
