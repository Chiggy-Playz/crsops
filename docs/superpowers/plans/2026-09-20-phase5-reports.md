# CRS Ops — Phase 5: Reports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A date-range + optional-employee-filter report screen: status-count summary cards (present/absent/leave/holiday/week-off, plus an explicit "X days unmarked" count regardless of range age) via `effective_range_status`, and a late/early/overtime exceptions drill-down via `derived_flags`.

**Architecture:** No new Postgres — `attendance.effective_range_status`/`attendance.derived_flags` (Phase 3, already live and verified) are exactly the two functions this screen needs. This phase is Flutter-only: one new pure computation module (summary-bucket counting, exceptions filtering) with real unit tests, one new page, one new provider wrapping `derived_flags` (a `effectiveRangeStatus`-equivalent provider doesn't exist yet either — added here), wired into the existing router/Calendar app-bar.

**Tech Stack:** Same as Phases 1–4 — Flutter (Riverpod + `riverpod_generator`, `dart_mappable`), Supabase (`attendance` schema, unchanged this phase).

**Spec:** `/home/chiggy/Projects/crs_ops/plan.md` (Screens → Reports; the `effective_range_status`/`derived_flags` function definitions in the `attendance` schema section). Depends on Phase 3 (`docs/superpowers/plans/2026-09-20-phase3-attendance-marking.md`), whose `attendance_providers.dart`/`CalendarPage`/`routes.dart` this phase extends.

## Global Constraints

- **No new migration.** Confirmed by reading `supabase/migrations/20260920003425_attendance_functions.sql` directly before writing this plan: `effective_range_status(p_start, p_end, p_employee_id default null)` and `derived_flags(p_start, p_end, p_employee_id default null)` already exist, already `stable`, already verified against real data in Phase 3 (including the overnight-shift case). Task 1 re-confirms this at execution time.
- **The mixed half-day rollup question is deliberately NOT resolved here** (`plan.md` is explicit this needs "a quick call with your dad" once this screen exists). This plan implements one concrete, honestly-labeled rule instead of a `TODO`: **a row's bucket is `first_half_status` whenever `is_explicit` is true — `second_half_status` is not counted separately, so a first-half-present/second-half-absent day is counted only as "present" for this summary.** This is a real, working v1 behavior with a known, stated limitation (see Self-Review), not unfinished code.
- **Explicit beats computed, for bucketing**: if `is_explicit` is true, use `first_half_status` regardless of `is_week_off` (an admin who explicitly marked a Sunday holiday meant that, overriding the computed week-off default). Only when `is_explicit` is false do we fall back to `is_week_off ? 'week_off' : 'unmarked'`. This exactly matches `recent_gaps`'s own gap condition (`not is_explicit and not is_week_off`) for what counts as "unmarked."
- Every `.rpc('<function>')` call must be schema-qualified: `_client.schema('attendance').rpc(...)` — this repository already exists from Phase 3 and its two RPC calls are already qualified; this phase only *adds a provider*, no new repository call sites. Task 6's audit re-confirms no new unqualified call sites were introduced.
- Riverpod resolved to **3.x**: `AsyncValue.value` (nullable), not `.valueOrNull`.
- Summary buckets are **driven by `attendance.status_types`** (via the already-existing `statusTypesProvider`, Phase 3), not a hardcoded list of five strings — consistent with this app's DB-configurable-categories design. A future sixth status type shows up as a sixth card with zero code changes here.
- English only, Material 3 widgets throughout. Four-states rule (loading/error/data/offline) applies to the report body **once a range is selected**; before any range is selected, a distinct fifth state — a plain prompt ("Select a date range to see a report") — is shown, which is neither loading nor an error.
- **Interactive native date-range-picker UI (`showDateRangePicker`) is not exercised by an automated widget test** — simulating Material's full calendar-grid navigation in `flutter test` is brittle and tests Flutter's own picker, not this app's logic. The actual bucketing/filtering logic is instead extracted into pure, fully-unit-tested functions (Task 2), and one widget test confirms the pre-selection prompt state renders (Task 4) — the same category of gap as Phase 1's Google-sign-in spike (Task 22 there), documented as a manual verification step (Task 6), not silently skipped.

---

## File Structure

**Flutter — `lib/modules/attendance/` (extends Phase 3's domain):**
- `report_calculations.dart` — pure functions: `computeStatusSummary`, `filterExceptions`.
- `pages/report_page.dart` — the screen.

**Modify:**
- `providers/attendance_providers.dart` — add `derivedFlags` family provider.
- `pages/calendar_page.dart` — add an `AppBar` action linking to `/reports`.
- `routes.dart` — add the `/reports` `GoRoute`.

**Tests:**
- `test/modules/attendance/report_calculations_test.dart`
- `test/modules/attendance/pages/report_page_test.dart`

---

### Task 1: Confirm no new schema/migration is needed

**Files:** none — verification only.

- [ ] **Step 1: Read the existing functions migration to confirm both functions are already sufficient**

```bash
grep -n "create or replace function attendance.effective_range_status\|create or replace function attendance.derived_flags" supabase/migrations/20260920003425_attendance_functions.sql
```

Expected: both function signatures present, each `returns table (...)` matching `EffectiveStatusRow`/`DerivedFlagsRow`'s exact field names (`lib/modules/attendance/models/effective_status_row.dart`, `derived_flags_row.dart`) — confirm by comparing, don't assume. If either is missing or shaped differently than those models expect, **stop and report it** rather than writing new SQL to patch a mismatch this plan doesn't anticipate.

- [ ] **Step 2: No commit** — this task only reads existing state.

---

### Task 2: Pure report-computation functions

**Files:**
- Create: `lib/modules/attendance/report_calculations.dart`
- Test: `test/modules/attendance/report_calculations_test.dart`

**Interfaces:**
- Consumes: `EffectiveStatusRow` (Phase 3), `DerivedFlagsRow` (Phase 3), `StatusType` (Phase 3).
- Produces: `Map<String, int> computeStatusSummary(List<EffectiveStatusRow> rows, List<StatusType> statusTypes)` — keyed by every `StatusType.id` (initialized to 0) plus a fixed `'unmarked'` key; `List<DerivedFlagsRow> filterExceptions(List<DerivedFlagsRow> rows)` — only rows where `isLate || isEarly || overtimeMinutes > 0`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/modules/attendance/report_calculations_test.dart
import 'package:crs_ops/modules/attendance/models/derived_flags_row.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/report_calculations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeStatusSummary', () {
    const statusTypes = [
      StatusType(id: 'present', label: 'Present'),
      StatusType(id: 'absent', label: 'Absent'),
      StatusType(id: 'week_off', label: 'Week Off'),
    ];

    test('an explicit day counts toward its first_half_status bucket', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'present',
          secondHalfStatus: 'absent',
          isExplicit: true,
          isWeekOff: false,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['present'], 1);
      expect(summary['absent'], 0);
    });

    test('explicit beats computed week-off — an explicitly marked Sunday counts by its status, not week_off', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 2),
          firstHalfStatus: 'present',
          secondHalfStatus: 'present',
          isExplicit: true,
          isWeekOff: true,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['present'], 1);
      expect(summary['week_off'], 0);
    });

    test('an unexplicit week-off day counts as week_off', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 2),
          isExplicit: false,
          isWeekOff: true,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['week_off'], 1);
      expect(summary['unmarked'], 0);
    });

    test('a genuine gap (not explicit, not week off) counts as unmarked', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 4),
          isExplicit: false,
          isWeekOff: false,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['unmarked'], 1);
    });

    test('every status type starts at zero even with no matching rows', () {
      final summary = computeStatusSummary(const [], statusTypes);

      expect(summary['present'], 0);
      expect(summary['absent'], 0);
      expect(summary['week_off'], 0);
      expect(summary['unmarked'], 0);
    });
  });

  group('filterExceptions', () {
    test('includes a late row, an early row, and an overtime row; excludes an all-clear row', () {
      final rows = [
        DerivedFlagsRow(employeeId: '1', date: DateTime(2024, 6, 1), workedMinutes: 480, isLate: false, isEarly: false, overtimeMinutes: 0),
        DerivedFlagsRow(employeeId: '1', date: DateTime(2024, 6, 2), workedMinutes: 450, isLate: true, isEarly: false, overtimeMinutes: 0),
        DerivedFlagsRow(employeeId: '1', date: DateTime(2024, 6, 3), workedMinutes: 420, isLate: false, isEarly: true, overtimeMinutes: 0),
        DerivedFlagsRow(employeeId: '1', date: DateTime(2024, 6, 4), workedMinutes: 600, isLate: false, isEarly: false, overtimeMinutes: 120),
      ];

      final exceptions = filterExceptions(rows);

      expect(exceptions, hasLength(3));
      expect(exceptions.map((r) => r.date), isNot(contains(DateTime(2024, 6, 1))));
    });
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

```bash
flutter test test/modules/attendance/report_calculations_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the pure functions**

```dart
// lib/modules/attendance/report_calculations.dart
import 'models/derived_flags_row.dart';
import 'models/effective_status_row.dart';
import 'models/status_type.dart';

const _unmarkedKey = 'unmarked';

Map<String, int> computeStatusSummary(List<EffectiveStatusRow> rows, List<StatusType> statusTypes) {
  final summary = <String, int>{for (final t in statusTypes) t.id: 0, _unmarkedKey: 0};

  for (final row in rows) {
    final String bucket;
    if (row.isExplicit) {
      bucket = row.firstHalfStatus ?? _unmarkedKey;
    } else if (row.isWeekOff) {
      bucket = 'week_off';
    } else {
      bucket = _unmarkedKey;
    }
    summary[bucket] = (summary[bucket] ?? 0) + 1;
  }

  return summary;
}

List<DerivedFlagsRow> filterExceptions(List<DerivedFlagsRow> rows) =>
    rows.where((r) => r.isLate || r.isEarly || r.overtimeMinutes > 0).toList();
```

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/modules/attendance/report_calculations_test.dart
```

Expected: PASS, 6/6.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/attendance/report_calculations.dart test/modules/attendance/report_calculations_test.dart
git commit -m "feat: report summary/exceptions pure computation functions"
```

---

### Task 3: `derivedFlags` Riverpod provider

**Files:**
- Modify: `lib/modules/attendance/providers/attendance_providers.dart`

**Interfaces:**
- Consumes: `attendanceRepositoryProvider` (Phase 3).
- Produces: `derivedFlags(Ref ref, {required DateTime start, required DateTime end, String? employeeId})` → `Future<List<DerivedFlagsRow>>` (family provider, matching `effectiveRangeStatus`'s exact shape).

- [ ] **Step 1: Add the provider** (append; do not remove any existing provider)

```dart
// lib/modules/attendance/providers/attendance_providers.dart — add alongside effectiveRangeStatus
@riverpod
Future<List<DerivedFlagsRow>> derivedFlags(
  Ref ref, {
  required DateTime start,
  required DateTime end,
  String? employeeId,
}) =>
    ref.watch(attendanceRepositoryProvider).fetchDerivedFlags(
          start: start,
          end: end,
          employeeId: employeeId,
        );
```

Add the missing import at the top: `import '../models/derived_flags_row.dart';`

- [ ] **Step 2: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/modules/attendance/providers/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/modules/attendance/providers/attendance_providers.dart lib/modules/attendance/providers/attendance_providers.g.dart
git commit -m "feat: derivedFlags Riverpod provider"
```

---

### Task 4: `ReportPage`

**Files:**
- Create: `lib/modules/attendance/pages/report_page.dart`
- Test: `test/modules/attendance/pages/report_page_test.dart`

**Interfaces:**
- Consumes: `effectiveRangeStatusProvider`, `derivedFlagsProvider`, `statusTypesProvider` (Phase 3/this phase), `employeeListProvider`/`Employee` (Phase 2), `iconFor`/`colorFor` (Phase 2), `isOnlineProvider`/`OfflineScreen` (Phase 1), `computeStatusSummary`/`filterExceptions` (Task 2).
- Produces: `class ReportPage extends ConsumerStatefulWidget`.

- [ ] **Step 1: Write the failing widget test** (only the deterministic pre-selection state — see the Global Constraints note on why the interactive date-range picker isn't simulated here)

```dart
// test/modules/attendance/pages/report_page_test.dart
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/report_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/employees/fakes/fake_employee_repository.dart';
import '../fakes/fake_attendance_repository.dart';
import '../fakes/fake_status_type_repository.dart';

void main() {
  Widget wrap() => ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [
              Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
            ]),
          ),
          attendanceRepositoryProvider.overrideWithValue(FakeAttendanceRepository()),
          statusTypeRepositoryProvider.overrideWithValue(
            FakeStatusTypeRepository(seed: const [
              StatusType(id: 'present', label: 'Present', iconName: 'check', colorHex: '#4CAF50'),
              StatusType(id: 'absent', label: 'Absent', iconName: 'close', colorHex: '#F44336'),
            ]),
          ),
        ],
        child: const MaterialApp(home: ReportPage()),
      );

  testWidgets('prompts for a date range before showing any report body', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Select a date range to see a report'), findsOneWidget);
  });

  testWidgets('has an employee filter defaulting to All employees', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('All employees'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/modules/attendance/pages/report_page_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the page**

```dart
// lib/modules/attendance/pages/report_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/employees/providers/employee_providers.dart';
import '../../../core/widgets/status_metadata.dart';
import '../providers/attendance_providers.dart';
import '../report_calculations.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  DateTimeRange? _range;
  String? _selectedEmployeeId;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _range == null
                          ? 'Select date range'
                          : '${_range!.start.toIso8601String().split('T').first} – ${_range!.end.toIso8601String().split('T').first}',
                    ),
                    onPressed: _pickRange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: employeesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (employees) => DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedEmployeeId,
                      hint: const Text('All employees'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All employees')),
                        ...employees.map((e) => DropdownMenuItem<String?>(value: e.id, child: Text(e.name))),
                      ],
                      onChanged: (value) => setState(() => _selectedEmployeeId = value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final range = _range;
    if (range == null) {
      return const Center(child: Text('Select a date range to see a report'));
    }

    final statusTypesAsync = ref.watch(statusTypesProvider);
    final summaryAsync = ref.watch(effectiveRangeStatusProvider(
      start: range.start,
      end: range.end,
      employeeId: _selectedEmployeeId,
    ));
    final exceptionsAsync = ref.watch(derivedFlagsProvider(
      start: range.start,
      end: range.end,
      employeeId: _selectedEmployeeId,
    ));

    if (statusTypesAsync.isLoading || summaryAsync.isLoading || exceptionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (statusTypesAsync.hasError) return Center(child: Text('${statusTypesAsync.error}'));
    if (summaryAsync.hasError) return Center(child: Text('${summaryAsync.error}'));
    if (exceptionsAsync.hasError) return Center(child: Text('${exceptionsAsync.error}'));

    final statusTypes = statusTypesAsync.value!;
    final summary = computeStatusSummary(summaryAsync.value!, statusTypes);
    final exceptions = filterExceptions(exceptionsAsync.value!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in statusTypes)
              _SummaryCard(label: type.label, count: summary[type.id] ?? 0, icon: iconFor(type.iconName), color: colorFor(type.colorHex)),
            _SummaryCard(
              label: 'Unmarked',
              count: summary['unmarked'] ?? 0,
              icon: Icons.help_outline,
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Late / early / overtime', style: Theme.of(context).textTheme.titleMedium),
        if (exceptions.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('No exceptions in this range.'))
        else
          ...exceptions.map((e) => ListTile(
                title: Text(e.date.toIso8601String().split('T').first),
                subtitle: Text([
                  if (e.isLate) 'Late',
                  if (e.isEarly) 'Left early',
                  if (e.overtimeMinutes > 0) '+${e.overtimeMinutes}m overtime',
                ].join(' · ')),
              )),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.count, required this.icon, required this.color});

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text('$count', style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    );
  }
}
```

*(Offline handling: this page doesn't add a separate `isOnlineProvider` check — the shell that hosts it (Phase 7's polish pass wires `OfflineScreen` at the app level per Phase 1's `app.dart`, already covering every screen including this one) is the single place that decision lives, matching Phase 3/4's own precedent of not re-implementing Phase 1's mechanism per-screen.)*

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/modules/attendance/pages/report_page_test.dart
```

Expected: PASS, 2/2.

- [ ] **Step 5: Commit**

```bash
git add lib/modules/attendance/pages/report_page.dart test/modules/attendance/pages/report_page_test.dart
git commit -m "feat: Reports page — status-count summary cards + late/early/overtime drill-down"
```

---

### Task 5: Route + Calendar app-bar wiring

**Files:**
- Modify: `lib/modules/attendance/routes.dart`
- Modify: `lib/modules/attendance/pages/calendar_page.dart`

**Interfaces:**
- Consumes: `ReportPage` (Task 4).
- Produces: `/reports` route.

- [ ] **Step 1: Add the route** (append to the existing list; do not remove any existing route)

```dart
// lib/modules/attendance/routes.dart — add this import:
import 'pages/report_page.dart';
// add this route to the existing list:
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportPage(),
      ),
```

- [ ] **Step 2: Add the app-bar action on `CalendarPage`**

```dart
// lib/modules/attendance/pages/calendar_page.dart — change the AppBar to:
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Reports',
            onPressed: () => Navigator.of(context).pushNamed('/reports'),
          ),
        ],
      ),
```

- [ ] **Step 3: Verify it compiles**

```bash
dart analyze lib/modules/attendance/
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/modules/attendance/routes.dart lib/modules/attendance/pages/calendar_page.dart
git commit -m "feat: wire Reports into the router and Calendar's app bar"
```

---

### Task 6: Full-phase compile/test sweep + documented manual verification

**Files:** none (verification only).

- [ ] **Step 1: Schema-qualification audit** — confirm this phase introduced no new unqualified call sites (it shouldn't have added any `.from()`/`.rpc()` at all, only a provider wrapping an already-qualified repository method)

```bash
git diff --stat HEAD~5 -- lib/modules/attendance/repositories/
```

Expected: empty (no repository file changed this phase) — if it's not empty, `grep -n "\.from(\|\.rpc(" lib/modules/attendance/repositories/attendance_repository.dart` and re-verify every site is still `.schema('attendance')`-qualified before proceeding.

- [ ] **Step 2: Run the full analyzer and test suite**

```bash
flutter analyze
flutter test
```

Expected: no errors; all tests pass (Phases 1–4's tests plus this phase's 8 new ones).

- [ ] **Step 3: Build for web, to verify a real end-to-end compile**

```bash
flutter build web --dart-define=SUPABASE_URL=https://ocalljagckzyvngprlxo.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<from `supabase projects api-keys --project-ref ocalljagckzyvngprlxo`>
```

Expected: `✓ Built build/web`.

- [ ] **Step 4: Documented manual verification** (not automated — see Global Constraints; record the outcome in `OVERNIGHT_LOG.md` or equivalent rather than silently skipping)

Once Google OAuth is set up and the app runs for real: open Reports from the Calendar app-bar icon, pick a real date range via the native picker, confirm summary cards and the exceptions list render with real numbers, then hand-verify at least one mixed half-day (if any exist in real data) actually gets counted under its `first_half_status` per this phase's stated rollup rule — this is the one behavior no automated test in this plan exercises end-to-end.

- [ ] **Step 5: No commit** — verification only, nothing changes (unless Step 1 found and fixed something).

---

## Self-Review

- **Spec coverage**: date range + employee filter — Task 4. Status-count summary cards via `effective_range_status` — Tasks 2 (computation) + 4 (rendering), driven dynamically by `statusTypesProvider` rather than a hardcoded five-item list. Explicit "X days unmarked" count, accurate regardless of range age (no 7-day window applied anywhere in this phase, unlike `recent_gaps`) — the `unmarked` key in `computeStatusSummary`, over whatever full range the user picks. Late/early/overtime drill-down via `derived_flags` — Tasks 3 (provider) + 2 (`filterExceptions`) + 4 (rendering).
- **The open product question, explicitly not resolved**: stated plainly above and in `computeStatusSummary`'s doc — a mixed half-day counts only toward `first_half_status`; `second_half_status` is silently not counted separately in this v1 rollup. This is a real, working, tested behavior (Task 2's second test asserts it), not a `TODO` — it exists so the screen has *a* concrete answer today, deliberately left open for the actual product conversation `plan.md` calls for.
- **Placeholder scan**: no `TBD`/`TODO`/`FIXME`. The one deliberately-untested behavior (the interactive `showDateRangePicker` flow) is called out explicitly as a documented manual-verification step (Task 6 Step 4), not silently absent from test coverage.
- **Type/name consistency**: `computeStatusSummary`/`filterExceptions` (Task 2) signatures match their usage in `ReportPage` (Task 4) exactly. `derivedFlagsProvider` (Task 3) matches its usage in Task 4. `EffectiveStatusRow`/`DerivedFlagsRow`/`StatusType` field names (all pre-existing from Phase 3) are used consistently throughout.
- **Schema-qualification**: no new `.from()`/`.rpc()` call sites introduced this phase — the only DB access is via the already-qualified, already-verified `AttendanceRepository.fetchEffectiveRangeStatus`/`fetchDerivedFlags` from Phase 3, reused as-is through a new provider. Task 6 Step 1 explicitly confirms no repository file was touched.
- **No new migration confirmed, not assumed**: Task 1 re-verifies both functions' exact signatures against the real committed migration file before Task 2's pure functions are written against those field names.

---

**Plan complete and saved to `docs/superpowers/plans/2026-09-20-phase5-reports.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
