# Adaptive wide-screen layouts — design

**Date:** 2026-10-05 · **Status:** draft, awaiting review

## Problem

On web and desktop every page is the phone layout stretched across the window
(screenshots, 2026-10-05, ~1930 px wide):

- Calendar: seven ~280 px columns, day numbers floating, gap ⚠ markers drifting to
  the cells' far corners, two-thirds of the screen empty.
- Day page: rows hug the left edge, "Mark all present" FAB in the far bottom-right.
- Reports: filters centred, cards and text left-aligned, calendar full width.
- Employees: search bar centred (its own max width), list hugs the left.
- Employee detail: header centred, rows left, ⋮ menu ~1900 px away; "+ Add" opens a
  phone bottom sheet mid-screen.
- Report range menu opens at a hardcoded screen position
  (`RelativeRect.fromLTRB(100, 100, …)`), not under its button.
- The address bar shows `/#/…` and doesn't follow pushed pages.

## Goal

Use M3's adaptive guidance (window size classes, canonical layouts) so wide screens
get real two-pane layouts, while phones keep today's behaviour unchanged.

## Decisions

### D1. Window size classes

`lib/core/layout/window_size.dart`: maps width to M3 classes, with a
`BuildContext` extension.

| Width | Class | Layout |
|---|---|---|
| < 600 | compact | phone layout (unchanged) |
| 600–839 | medium | phone layout + nav rail (unchanged) |
| ≥ 840 | expanded | two panes for Attendance, Employees, Settings |
| ≥ 1200 | large | Reports two-column dashboard |

### D2. Two panes via a ShellRoute per section

Each section's routes are wrapped in a go_router `ShellRoute` (its own navigator)
whose builder lays out:

- **expanded+**: `Row[ left pane (fixed width) | divider | routed child ]`
- **narrower**: just the routed child — so phones keep today's navigation and
  back stack.

The URL selects the right pane; links, refresh and browser back keep working.

| Section | Left pane | Right pane by URL | Nothing selected (wide) |
|---|---|---|---|
| Attendance | calendar, ~480 px | `/attendance/:date` → that day's list | `/attendance/calendar` **redirects to today's date** (decided: today pre-selected, zero clicks for the daily marking) |
| Employees | list + search, ~360 px | `/employees/:id` → detail | "Select an employee" empty state |
| Settings | hub list, ~360 px | `/settings/...` → that manager page | "Choose a setting" empty state |

- The left pane highlights the current selection, derived from the current location:
  the selected date gets a filled circle, and the selected row is highlighted.
- On wide screens, selecting in the left pane **replaces** the right pane
  (`go`), rather than stacking pages (`push`).
- Wide→narrow while a right-pane page is showing: that page shows alone; its
  back arrow goes to the section's list/calendar when there's nothing to pop.
- **Reports is not in a shell** — its own full page (D5).
- Attendance routes are all in `lib/modules/attendance/routes.dart`, so the
  Attendance shell can be typed (`@TypedShellRoute`) with Calendar and Day inside.
  Reports moves outside it. Settings and Employees routes span several files /
  include root-navigator sub-routes, so their shells are built by hand in
  `lib/app_router.dart` around the existing typed routes. New/edit employee keep
  targeting the root navigator, as nested sub-routes (already the case).
- Shell layouts live with their sections:
  `lib/modules/attendance/pages/attendance_split_layout.dart`,
  `lib/core/employees/pages/employees_split_layout.dart`,
  `lib/core/settings/pages/settings_split_layout.dart`, built on one shared
  `lib/core/layout/two_pane_layout.dart` (pane widths, divider, compact
  pass-through).

### D3. Actions and menus on wide screens

On expanded+, FABs move into their pane's header bar (desktop pattern, e.g. Gmail's
message toolbar: actions sit next to the content they affect):

- "✓ Mark all present" → day pane header.
- "+ Add ▾" → employee detail pane header, opening an **anchored, animated
  `MenuAnchor`** (Event / Payment) instead of the bottom sheet.
- "+ Add employee" → **both placements behind a temporary switch**: list pane
  header vs top of the nav rail (Google's Compose/New pattern). The user tries
  both, and the loser is deleted before committing.

Compact keeps the FABs and the bottom sheet unchanged.

### D4. Empty states

Shared `lib/core/widgets/empty_state.dart`: a large icon inside a soft circle
(theme container colour), then a headline and one line of help text. Used for
"Select an employee", "Choose a setting", and the existing plain-text empty
messages ("No employees yet", "No history yet", …) so they all match. An SVG
illustration (e.g. unDraw, recoloured) can replace the icon later; start with the
icon.

### D5. Reports

- **large (≥ 1200)**: two columns. Left: summary cards + late/early/overtime list.
  Right: the calendar at ~560 px.
- **below large**: one centred column, max 840 px.
- Filters left-aligned (fixes the centred/left mismatch).
- Range menu → anchored, animated `MenuAnchor` under its button.
- New preset **Previous month**: the 1st to the last day of last month
  (`DateTime(y, m - 1, 1)` → `DateTime(y, m, 0)`, which handles January).

### D6. Fixes across the app

- **Max content width** 840 px, centred, on single-pane pages that would
  otherwise stretch (e.g. Settings manager pages on medium widths).
- **Calendar gap ⚠ marker** placed next to the day number instead of the cell's
  top-right corner, so it doesn't drift on wide cells.
- **Clean URLs**: `usePathUrlStrategy()` in `main.dart`, and
  `GoRouter.optionURLReflectsImperativeAPIs = true` so pushed pages update the
  address bar (two-pane layouts depend on the URL being accurate).

## Deployment note

Hosting isn't decided. Clean URLs work with `flutter run` as-is. Any production
host must rewrite every path to `index.html` (single-page-app fallback), or a
refresh on e.g. `/employees/abc` returns 404. Cloudflare Pages does this
automatically; Netlify, Vercel and Firebase Hosting each need one rewrite rule.

## Out of scope

- Medium-width (600–839) two-pane layouts. Medium keeps the single pane.
- Nav drawer / expanded rail on large screens (three destinations fit the rail).
- An SVG illustration for empty states (D4: icon first).

## Build order

Each step leaves the app working, with `flutter analyze` clean and the existing
suite green.

1. `window_size.dart`, `two_pane_layout.dart`, `EmptyState`, max-width helper; clean
   URLs + URL reflection.
2. Attendance shell: calendar + day pane, today redirect, selection highlight,
   ⚠ marker fix, "Mark all present" in the pane header on wide.
3. Employees shell: list + detail, empty state, selection highlight, anchored
   "+ Add ▾" menu on wide, both "Add employee" placements behind a temporary switch.
4. Settings shell: hub + manager page, empty state.
5. Reports: responsive dashboard, anchored range menu, Previous month.
6. Manual check by the user (both "Add employee" variants), then delete the losing
   variant.

## Testing

Existing tests are updated as files change. After the user checks it by hand, new tests:

- window size class boundaries (599/600, 839/840, 1199/1200);
- two panes at 1000 px vs single pane at 400 px for each section;
- wide `/attendance/calendar` redirects to today; narrow does not;
- empty states render on wide `/employees` and `/settings`;
- Previous month range, including when the current month is January.

**Manual checklist for the user** (desktop web + phone):

- Each section at a wide window: left pane + right pane, selection highlighted,
  clicking swaps the right pane, browser back/refresh behave.
- Resize wide → narrow on a day / employee: single page, back arrow works.
- Actions in pane headers on wide; FABs and bottom sheet unchanged on phone.
- Both "Add employee" placements, then pick one.
- Reports at ≥ 1200 and below; range menu opens under its button; Previous month.
- URLs have no `#` and follow every navigation.
