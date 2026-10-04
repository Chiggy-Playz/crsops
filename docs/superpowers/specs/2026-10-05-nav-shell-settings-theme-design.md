# Nav shell, Settings → core, theme toggle — design

**Date:** 2026-10-05 · **Status:** draft, awaiting review

## Goal

1. Give the app a persistent navigation shell (bottom bar on phones, nav rail on wider
   screens) with one destination per module.
2. Move Settings into `core/`. It's app-wide, not a feature module, and today it and
   Attendance import each other's routes.
3. Add a System / Light / Dark theme toggle to Settings, persisted per device.

Along the way, remove every `core/ → modules/` import and fix an existing redirect
loop (see "Landing").

## Current state (what changes)

- `lib/app.dart` sets `theme` and `darkTheme` but no `themeMode`, so the app already
  follows the OS theme. There's no in-app control.
- `lib/core/widgets/adaptive_nav_scaffold.dart` exists (bottom bar below 600 px,
  rail above) but isn't mounted anywhere.
- The Calendar is the home screen. Its app bar pushes Employees, Reports and Settings.
- `lib/core/router/app_router.dart` and `lib/core/router/redirect_logic.dart` import
  `modules/attendance` and `modules/settings`. `redirect_logic.dart` hardcodes the
  `/attendance/` access check and the superadmin/admin path sets.
- `lib/modules/settings/` (hub + allow-list, roles, module-access managers) and
  `lib/modules/attendance/` import each other's `routes.dart`.
- Any user with a role can open `/employees`.

## Decisions

### D1. One destination per section, max 5

Bar/rail order: `Attendance · (Challan) · (Asset) · Employees · Settings`. Challan and
Asset are the only other modules expected, so 5 destinations at most, which is the
bottom bar's limit. A drawer-based module switcher was considered and rejected: it
only pays off past ~5 modules, and since most modules have one main screen, a
per-module bottom bar would keep appearing and disappearing.

### D2. Who sees what

| Section | Location | Visible when |
|---|---|---|
| Attendance | `lib/modules/attendance/` | `session.hasModuleAccess(ModuleNames.attendance)` |
| Challan / Asset (future) | `lib/modules/…` | module access, same pattern |
| Employees | `lib/core/employees/` | `session.isAdminOrAbove` (**new restriction**) |
| Settings | `lib/core/settings/` | every user with a role |

Employees lives in `core/` because several modules depend on it (attendance today,
challan "delivered by" and asset "assigned to" later, plus the ledger). Being in core
is about code dependency, not visibility.

### D3. `AppSection`: each section describes itself to core

Core owns one type. Every destination, the two core ones included, is a value of it:

```dart
// lib/core/sections/app_section.dart
class AppSection {
  final String label;                             // 'Attendance'
  final IconData icon;
  final IconData selectedIcon;
  final bool Function(AppSession) canAccess;      // nav visibility AND URL guard
  final String pathPrefix;                        // '/attendance' — owns it and everything under it
  final bool isLandingCandidate;                  // false for Settings (see D8)
  final String homeLocation;                      // '/attendance/calendar'
  final List<RouteBase> routes;                   // its generated typed routes
  final String? settingsGroupTitle;               // defaults to label
  final List<SettingsEntry> settingsEntries;      // rows in the Settings hub
  final List<RouteBase> settingsRoutes;           // pages those rows open
  final Map<String, bool Function(AppSession)> roleGuards;  // location → check
}

class SettingsEntry {
  final IconData icon;
  final String title;
  final bool Function(AppSession) canSee;
  final void Function(BuildContext) open;         // typed push, written in the section
}
```

Named `AppSection`, not `AppModule`, so it doesn't collide with *database* modules
(`ModuleNames`, `core.module_access`). Employees and Settings are sections but not
DB modules.

Files:
- `lib/modules/attendance/attendance_section.dart`
- `lib/core/employees/employees_section.dart`
- `lib/core/settings/settings_section.dart`

### D4. Composition root lives outside core

- `lib/app_sections.dart` holds `final allSections = [attendanceSection, employeesSection, settingsSection];`
  in bar order. It's the only file that imports every section.
- `lib/core/router/app_router.dart` moves to `lib/app_router.dart` and builds the
  router from `allSections`.
- Core reads the list through `appSectionsProvider` (in `lib/core/sections/`). It
  throws unless overridden, and `main.dart` overrides it with `allSections`. Tests
  override it with fake sections.

After this, nothing under `lib/core/` imports `lib/modules/`.

### D5. Shell routing

- One `StatefulShellRoute.indexedStack`, built by hand in `lib/app_router.dart`, with
  **one branch per section** (all of `allSections`, regardless of the current user).
  Each branch holds that section's generated typed routes. Every branch keeps its
  own navigation stack: switching tabs and back returns you to where you were.
- go_router_builder's `@TypedStatefulShellRoute` isn't used because it requires the
  whole tree in one annotated file, which defeats per-section route files. Typed
  navigation (`const CalendarRoute().push(context)`) works as before.
- **Settings branch:** holds Settings' own routes plus every section's
  `settingsRoutes`. That way, pages opened from the Settings hub (Shift defaults,
  Status types, Event types) stay inside the Settings tab with Settings highlighted,
  instead of jumping to another tab. These pages move to `/settings/…` paths:
  - `/attendance/shift-defaults` → `/settings/attendance/shift-defaults`
  - `/attendance/status-types` → `/settings/attendance/status-types`
  - `/employees/event-types` → `/settings/employees/event-types`

  Convention: a section's settings pages live under `/settings/<section>/…`, so
  URLs can't collide between sections and show where a page comes from. Settings'
  own pages keep their current paths (`/settings/allow-list`, `/settings/roles`,
  `/settings/module-access`).

  Each section keeps these pages in a separate `settings_routes.dart` file (with its
  own generated `$appRoutes`), so its main routes and settings routes stay in
  separate lists. The page code stays in the owning section's folder.
- Auth routes (loading, sign-in, unauthorized, no-modules) stay outside the shell.

### D6. When the bar is visible

- **Bar stays** on browse and drill-down screens: Calendar, Reports, attendance day
  page (a working screen; users hop between days), employee list, employee detail,
  Settings hub, all manager pages (add/edit there already happens in dialogs).
- **Bar hidden** on focused tasks: new employee and edit employee. Their route classes
  set `static final $parentNavigatorKey = rootNavigatorKey;` so they push above the
  shell. `rootNavigatorKey` lives in `lib/core/router/navigator_keys.dart`.
- The same rule applies at every screen size. It matches real apps, where forms and
  compose screens cover the nav on phones and desktops alike.
- Fewer than 2 visible sections → no bar or rail (a bottom bar needs at least 2
  items). `AdaptiveNavScaffold` renders just the child in that case.

### D7. Secondary screens within a section

Reached from the section home screen's app bar. Attendance: the Calendar app bar keeps
only the 📊 Reports button. The Employees and Settings buttons are removed because
they're now destinations. If a future section grows 3+ equally important screens,
it gets top tabs inside the section, which doesn't affect the bar.

### D8. Redirect logic

`computeRedirect` stays a pure function in `lib/core/router/redirect_logic.dart`. It
gains a `sections` parameter and drops its module imports. Order:

1. Loading / error / signed-out / no-role handling: unchanged.
2. **Landing location** = `homeLocation` of the first section in `sections` with
   `isLandingCandidate` that `canAccess` the session. Settings sets
   `isLandingCandidate: false`, so a user who can only see Settings gets
   `/no-modules`.
3. For each section: if the location is under its `pathPrefix` (equal to it, or
   starting with `pathPrefix + '/'`, so `/employees` and `/employees/x` both match
   but `/employeesx` doesn't) and `!canAccess(session)` → landing location.
4. For each section's `roleGuards`: if the location matches and the check fails →
   landing location. These replace `_superadminPaths` / `_adminPaths` with the same
   rules:
   - Settings section: allow-list (superadmin), roles (superadmin), module access (admin+)
   - Employees section: event types (superadmin)
   - Attendance section: shift defaults (admin+), status types (admin+)
5. Signed-in user with a role on sign-in, unauthorized, loading, or no-modules →
   landing location (no-modules stays put if the landing *is* no-modules).

Guard failures go to the landing location instead of bouncing through
`/unauthorized`. The end result for the user is the same as today (the bounce already
ended on home), with fewer hops. `/unauthorized` is now reached only by a user with no
role.

The nav bar and the URL guard read the **same** `canAccess`, so hiding a destination
and blocking its URL (typed into a browser on web, or an old bookmark) can't drift
apart.

**Fixes an existing bug.** Today a user with a role but no attendance access is sent
to `/attendance/calendar`, bounced to `/unauthorized`, and bounced back to the
calendar: a redirect loop that go_router aborts with an error. Step 2 sends them to
an accessible section or `/no-modules` instead.

### D9. "No modules" page

`/no-modules` (in `lib/core/router/auth_routes.dart`, page in `lib/core/auth/pages/`)
is for a user who has a role but can't see any section except Settings. It shows "You
don't have access to any modules yet. Ask an admin to grant access." and has a ⚙️
app-bar button that opens Settings (theme, sign out). It's separate from
`/unauthorized`, which means "your account has no role". When access is granted, the
next session refresh routes them in through step 5.

### D10. Settings hub

`lib/core/settings/pages/settings_page.dart` renders:

1. **Appearance** (Settings' own, always shown): a "Theme" `ListTile` with a leading
   icon and the current choice as its subtitle ("System default" / "Light" /
   "Dark"). Tapping it opens a bottom sheet to pick one (see D11).
2. One group per section with at least one visible `SettingsEntry`, headed by
   `settingsGroupTitle ?? label`, in `allSections` order:
   - **Access** (Settings): Allow-list · Roles · Module access
   - **Employees**: Event types
   - **Attendance**: Shift defaults · Status types
3. Divider, then **Sign out**.

Regular staff see Appearance and Sign out only. Per-entry visibility rules are the
same as today.

### D11. Theme toggle

- `lib/core/theme/theme_mode_provider.dart`: a Riverpod notifier holding `ThemeMode`.
- Persisted with `shared_preferences` (added as a direct dependency; it's already
  in the lockfile as a transitive one) under key `theme_mode`, values `system` /
  `light` / `dark`. A missing or unknown value means System.
- `main.dart` awaits `SharedPreferences.getInstance()` before `runApp` and provides it
  through a `sharedPreferencesProvider` override, so the first frame already uses the
  saved theme (no light flash).
- Setting a mode updates state immediately and writes in the background. If the
  write fails, the choice still holds for this session and no error is shown, since
  it's a cosmetic preference.
- `lib/app.dart` adds `themeMode: ref.watch(themeModeProvider)`.
- **Picker UI:** a modal bottom sheet, following the pattern of hlna's
  `SelectionListview` (`~/Projects/hlna/hlna_app/lib/widgets/selection_listview.dart`):
  a title ("Theme"), then a grouped list of options with rounded outer corners and
  divider-coloured borders. The current option is tinted `primaryContainer`, and
  tapping an option closes the sheet and returns its value. Options: System default,
  Light, Dark, each with an icon.
- **Reusable helper:** `lib/core/widgets/selection_sheet.dart` exposes
  `Future<T?> showSelectionSheet<T>({context, title, options, selected})`, a port of
  `SelectionListview` for anything else that needs "pick one of a few". Differences
  from the hlna original:
  - The selected row also gets a trailing ✓ and `selected: true` semantics, so
    screen readers announce it (the tint alone isn't announced).
  - Options carry an optional leading icon.
  - Material 3's default sheet max width (640 px) keeps it from stretching across
    desktop windows.
  - Dismissing without picking returns `null`, which means no change.
- Clean-up: `Colors.grey` at `lib/modules/attendance/pages/report_page.dart:252` →
  `colorScheme.onSurfaceVariant`.

### D12. Enforce module access in RLS (migration written, **not applied**)

Today `core.has_module_access()` exists but no policy uses it, so module access is a
UI-only gate. A new migration adds it to the attendance `SELECT` policies.

The function already returns true for admin and above (and the client's
`AppSession.hasModuleAccess` mirrors this), so admin-only write policies
(`*_insert`, `*_update`, `attendance_days_write`) already imply module access and
stay unchanged. The change only affects non-admin users reading attendance data. The
attendance functions (`effective_range_status`, `recent_gaps`, `derived_flags`) are
plain `language sql` (security invoker), so they pick up the new policies
automatically.

File: `supabase/migrations/<timestamp>_enforce_attendance_module_access.sql`, created
in build step 5. **The user applies it**; Claude doesn't run `supabase db push` /
`db reset` or apply it any other way.

```sql
-- Module access was enforced only in the app's UI. Add it to every attendance
-- read policy so the database enforces it too. Admin-and-above always pass
-- core.has_module_access(), so admin-only write policies need no change.

drop policy shift_defaults_select on attendance.shift_defaults;
create policy shift_defaults_select on attendance.shift_defaults
  for select using (core.has_module_access('attendance'));

drop policy status_types_select on attendance.status_types;
create policy status_types_select on attendance.status_types
  for select using (core.has_module_access('attendance'));

drop policy attendance_days_select on attendance.attendance_days;
create policy attendance_days_select on attendance.attendance_days
  for select using (
    core.has_module_access('attendance')
    and (
      core.is_admin_or_above()
      or exists (
        select 1 from core.employees e
        where e.id = employee_id and e.user_id = auth.uid()
      )
    )
  );
```

## Known limitations (accepted, out of scope)

- **Revoked access isn't seen live.** `sessionProvider` only re-fetches role and
  module access on auth events (sign-in/out, ~hourly token refresh). A revoked user
  keeps the tab until then or until restart, but once D12 is applied the database
  refuses their attendance reads, so the stale tab just shows errors. Possible later
  fix: re-fetch on app resume.

## Build order

Each step leaves the app runnable, with `flutter analyze` clean and the existing suite
green. Tests broken mechanically by moves and renames are fixed within the step.

1. **Sections + composition root.** `AppSection`, `appSectionsProvider`, the three
   section files, `lib/app_sections.dart`, move `app_router.dart` to `lib/`, make
   redirect logic section-driven, add `/no-modules`. Routes still flat (no shell yet).
2. **Settings → core.** Move `lib/modules/settings/` to `lib/core/settings/`, move the
   settings-opened pages to `/settings/…` paths, render the hub from section entries.
3. **Nav shell.** `StatefulShellRoute` + `AdaptiveNavScaffold` (with the < 2 rule and
   index mapping), root navigator for new/edit employee, trim the Calendar app bar.
4. **Theme toggle.** Provider, persistence, Appearance group, `report_page` grey fix.
5. **RLS migration file** (D12). Written only; the user reviews and applies it.

Then **manual verification by the user**, then new tests (below).

## Testing

Per the agreed workflow: build first, the user verifies by hand, then tests are added.

**Updated during the build** (so the suite stays green):
`test/core/router/redirect_logic_test.dart` (rewritten for sections), the settings
tests moving from `test/modules/settings/` to `test/core/settings/`,
`test/core/widgets/adaptive_nav_scaffold_test.dart`,
`test/modules/attendance/pages/calendar_page_test.dart` (app bar buttons).

**Added after verification:**
- Redirect: landing picks the first accessible section; no-role → unauthorized;
  no sections → `/no-modules`; the old redirect-loop case now lands correctly;
  hidden-section URL → landing; role guards keep today's rules.
- Shell: bar shows only accessible sections; bar index ↔ branch index mapping;
  no bar with < 2 sections.
- Settings hub: groups and entries filtered by `canSee`; an empty group is hidden.
- Theme: saved value is restored; unknown value → System; selecting a mode updates
  and persists.
- Selection sheet: shows options with the current one marked selected; tapping
  returns its value; dismissing returns `null`.

**Manual checklist for the user:**
- Superadmin, admin, staff-with-attendance, staff-without-modules: correct
  destinations and landing for each.
- Tab state survives switching (open an employee, switch tabs, come back).
- New/edit employee cover the bar; day page and manager pages keep it.
- Phone width shows the bottom bar; wide window shows the rail.
- Theme: the row shows the current choice; the sheet marks it; picking one switches
  instantly, survives restart, and System follows the OS.
- Web: typing a hidden section's URL lands you on your home section.
- After applying the D12 migration locally: a staff user without attendance access
  gets no rows from `attendance.*` tables, while a staff user with access and admins
  are unaffected.

## Implementation notes (deviations found while building)

- **Employee routes are nested.** go_router 18 only lets a route inside a shell
  branch target the root navigator if it's a sub-route. So `new`, `:id` and
  `:id/edit` are declared under `/employees`. URLs are unchanged.
- **Custom branch container.** `StatefulShellRoute` uses
  `SectionNavShell.branchContainer` instead of `.indexedStack`. It disables heroes
  and tickers in hidden branches. Without it, pushing new employee above the shell
  saw one default-tagged FAB per live branch and asserted on duplicate hero tags.
- **Settings hub order:** Appearance, then Access (Settings' own group), then the
  other sections in nav order (Attendance, Employees).
- **Names:** the theme provider is `themeModeControllerProvider` (class
  `ThemeModeController`). The hub row "Attendance status types" became "Status
  types", since it now sits under an "Attendance" header.
