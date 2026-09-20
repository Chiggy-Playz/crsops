# CRS Ops — Phase 4: Finance Ledger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an admin record a manual, append-only ledger entry (salary payment, advance, etc.) against an employee, and see it appear in that employee's timeline alongside their events — closing out req. 5 from `plan.md`.

**Architecture:** `core.employee_ledger_entries` and the `core.employee_timeline` view that unions it with `core.employee_events` already exist (Phase 1's migration) — this phase is **Flutter-only**, no new schema. A new model/repository/provider follow the exact same shape as Phase 2's `EmployeeEvent`/`EmployeeEventRepository`, and a new "Add payment" dialog follows the exact same shape as Phase 2's "Add event" dialog, differing only in that `entry_type` has no lookup table (a confirmed design decision — typo-safety comes from a dropdown-of-existing-values-plus-freeform UI, not a table/FK).

**Tech Stack:** Same as Phases 1–3 — Flutter (Riverpod + `riverpod_generator`, `dart_mappable`), Supabase (`core` schema, unchanged this phase).

**Spec:** `/home/chiggy/Projects/crs_ops/plan.md` (sections: req. 5 in "New requirements," `core.employee_ledger_entries` + `core.employee_timeline` in the `core` schema, req. 6's `entry_type`-stays-plain-text discussion, Screens → Employee detail/timeline's "Add payment" dialog). Depends on Phase 2 (`docs/superpowers/plans/2026-09-20-phase2-employee-core.md`), whose `EmployeeDetailPage`/`employee_providers.dart`/`employeeTimelineProvider` this phase extends rather than replaces.

## Global Constraints

- **No new migration.** `core.employee_ledger_entries (id, employee_id, entry_date, amount numeric, entry_type text, note, created_by, created_at)` and `core.employee_timeline` (unions events + ledger entries, ordered by date) already exist and were verified working in Phase 1. Confirmed by reading `supabase/migrations/20260919223302_core_schema.sql` directly before writing this plan — Task 1 below re-confirms this at execution time too, rather than assuming.
- **`entry_type` has no lookup table, by design** (per `plan.md`'s req. 6 discussion: it carries no metadata the app reads, unlike `event_type`/attendance status, so a table would add a migration+FK for no functional gain). Typo-safety comes entirely from the UI: a dropdown of `select distinct entry_type from core.employee_ledger_entries order by 1` plus an explicit "add new" option that just lets the admin type a fresh string directly into the same field being submitted — there is no second repository call to "register" a new type first, unlike Phase 2's `EventTypeRepository.addDescriptiveType`.
- Every `.from('<table>')` call must be schema-qualified: `_client.schema('core').from('employee_ledger_entries')` — including when split across multiple lines. This exact bug recurred in Phases 1–2 before it stuck as a from-the-start habit in Phase 3; every call site in this phase is written qualified from the start, and Task 6's self-review re-checks via `grep`.
- Riverpod resolved to **3.x**: `AsyncValue.value` (nullable), not `.valueOrNull`.
- New providers are added to the **existing** `lib/core/employees/providers/employee_providers.dart` (modified, not a new file) — matching that file's own stated convention ("one file, small and tightly coupled") and Phases 1–3's precedent of one providers file per domain area.
- English only, Material 3 widgets throughout. No new async list page this phase (the ledger entry surfaces through the already-four-states-compliant `EmployeeDetailPage`'s timeline list, not a new screen), so no new four-states handling is needed beyond confirming the existing timeline list still covers it.

---

## File Structure

**Flutter — `lib/core/employees/` (extends Phase 2's domain, no new top-level folder):**
- `models/employee_ledger_entry.dart` — `EmployeeLedgerEntry` (`dart_mappable`).
- `repositories/employee_ledger_entry_repository.dart` — `abstract class EmployeeLedgerEntryRepository` + `SupabaseEmployeeLedgerEntryRepository`.
- `pages/widgets/add_payment_dialog.dart` — the dialog, mirroring `add_event_dialog.dart`'s structure.

**Modify:**
- `providers/employee_providers.dart` — add `employeeLedgerEntryRepositoryProvider`, `distinctEntryTypesProvider`.
- `pages/employee_detail_page.dart` — add an "Add payment" action alongside the existing "Add event" FAB (an `AppBar` action, not a second FAB — Scaffold only cleanly supports one primary FAB).

**Tests:**
- `test/core/employees/models/employee_ledger_entry_test.dart`
- `test/core/employees/fakes/fake_employee_ledger_entry_repository.dart`
- `test/core/employees/pages/employee_detail_page_test.dart` (modified — adds a case for the new "Add payment" action)

---

### Task 1: Confirm `core.employee_ledger_entries`/`core.employee_timeline` need no changes

**Files:** none — verification only.

- [ ] **Step 1: Read the existing migration to confirm the schema is already sufficient**

```bash
grep -n -A12 "create table core.employee_ledger_entries" supabase/migrations/20260919223302_core_schema.sql
grep -n -A8 "create view core.employee_timeline" supabase/migrations/20260919223302_core_schema.sql
```

Expected: `employee_ledger_entries` has exactly `id, employee_id, entry_date, amount, entry_type, note, created_by, created_at`, with RLS already enabled (`employee_ledger_entries_select`/`employee_ledger_entries_write` policies present); `employee_timeline` already `union all`s `core.employee_ledger_entries` in as `kind = 'ledger'`. If either is missing or shaped differently, **stop and report it** — do not write a new migration to patch it without understanding why Phase 1's already-verified migration doesn't match; this plan assumes it does, per direct confirmation while writing it.

- [ ] **Step 2: No commit** — this task only reads existing state.

---

### Task 2: `EmployeeLedgerEntry` model

**Files:**
- Create: `lib/core/employees/models/employee_ledger_entry.dart`
- Test: `test/core/employees/models/employee_ledger_entry_test.dart`

**Interfaces:**
- Produces: `class EmployeeLedgerEntry` (`dart_mappable`) — fields `String? id`, `String employeeId`, `DateTime entryDate`, `double amount`, `String entryType`, `String? note`, `String? createdBy`, `DateTime? createdAt`. `id`/`createdBy`/`createdAt` are nullable because the app constructs an entry *before* insert (no `id`/`createdAt` yet) as well as reads one back after (both present) — same optionality pattern as Phase 3's `AttendanceDay.id`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/employees/models/employee_ledger_entry_test.dart
import 'package:crs_ops/core/employees/models/employee_ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EmployeeLedgerEntry round-trips through JSON shapes matching Postgres output', () {
    final json = {
      'id': '33333333-3333-3333-3333-333333333333',
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'entry_date': '2024-02-01',
      'amount': 5000.0,
      'entry_type': 'advance',
      'note': 'urgent need',
      'created_by': null,
      'created_at': '2024-02-01T00:00:00.000Z',
    };

    final entry = EmployeeLedgerEntryMapper.fromMap(json);

    expect(entry.employeeId, '11111111-1111-1111-1111-111111111111');
    expect(entry.amount, 5000.0);
    expect(entry.entryType, 'advance');
    expect(entry.note, 'urgent need');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/models/employee_ledger_entry_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the model**

```dart
// lib/core/employees/models/employee_ledger_entry.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'employee_ledger_entry.mapper.dart';

@MappableClass()
class EmployeeLedgerEntry with EmployeeLedgerEntryMappable {
  const EmployeeLedgerEntry({
    this.id,
    required this.employeeId,
    required this.entryDate,
    required this.amount,
    required this.entryType,
    this.note,
    this.createdBy,
    this.createdAt,
  });

  @MappableField(key: 'id')
  final String? id;
  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'entry_date')
  final DateTime entryDate;
  @MappableField(key: 'amount')
  final double amount;
  @MappableField(key: 'entry_type')
  final String entryType;
  @MappableField(key: 'note')
  final String? note;
  @MappableField(key: 'created_by')
  final String? createdBy;
  @MappableField(key: 'created_at')
  final DateTime? createdAt;
}
```

- [ ] **Step 4: Generate mapper code and run the test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/employees/models/employee_ledger_entry_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/models/employee_ledger_entry.dart lib/core/employees/models/employee_ledger_entry.mapper.dart test/core/employees/models/employee_ledger_entry_test.dart
git commit -m "feat: EmployeeLedgerEntry model"
```

---

### Task 3: `EmployeeLedgerEntryRepository`

**Files:**
- Create: `lib/core/employees/repositories/employee_ledger_entry_repository.dart`

**Interfaces:**
- Consumes: `EmployeeLedgerEntry` (Task 2), `translateException` (Phase 1).
- Produces: `abstract class EmployeeLedgerEntryRepository` (`addEntry`, `fetchDistinctEntryTypes`) + `SupabaseEmployeeLedgerEntryRepository`. **Both call sites are `.schema('core')`-qualified.**

- [ ] **Step 1: Write the repository**

```dart
// lib/core/employees/repositories/employee_ledger_entry_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';

abstract class EmployeeLedgerEntryRepository {
  Future<void> addEntry({
    required String employeeId,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  });

  /// Powers the "Add payment" dialog's dropdown — typo-safety without a
  /// lookup table, per the design: pick an existing value rather than
  /// retype it, or type a genuinely new one (see Task 5's dialog).
  Future<List<String>> fetchDistinctEntryTypes();
}

class SupabaseEmployeeLedgerEntryRepository implements EmployeeLedgerEntryRepository {
  SupabaseEmployeeLedgerEntryRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> addEntry({
    required String employeeId,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  }) async {
    try {
      await _client.schema('core').from('employee_ledger_entries').insert({
        'employee_id': employeeId,
        'entry_date': entryDate.toIso8601String().split('T').first,
        'amount': amount,
        'entry_type': entryType,
        'note': note,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<String>> fetchDistinctEntryTypes() async {
    try {
      final rows = await _client
          .schema('core')
          .from('employee_ledger_entries')
          .select('entry_type')
          .order('entry_type');
      final types = rows.map((r) => r['entry_type'] as String).toSet().toList()..sort();
      return types;
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

*(`select('entry_type')` returns one row per ledger entry, not pre-deduplicated — PostgREST has no `distinct` query modifier, so dedup happens client-side via `.toSet()`. Fine at this app's scale — a "how many distinct payment categories exist" list is at most a few dozen rows, not worth a database round-trip's complexity to dedupe server-side.)*

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/core/employees/repositories/employee_ledger_entry_repository.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/employees/repositories/employee_ledger_entry_repository.dart
git commit -m "feat: EmployeeLedgerEntryRepository (schema-qualified)"
```

---

### Task 4: Fake repository + Riverpod providers

**Files:**
- Create: `test/core/employees/fakes/fake_employee_ledger_entry_repository.dart`
- Modify: `lib/core/employees/providers/employee_providers.dart`

**Interfaces:**
- Consumes: `EmployeeLedgerEntryRepository` (Task 3), `supabaseClientProvider` (Phase 1).
- Produces: `FakeEmployeeLedgerEntryRepository`; `employeeLedgerEntryRepositoryProvider` (`keepAlive`) → `EmployeeLedgerEntryRepository`; `distinctEntryTypesProvider` (`keepAlive`, matching `eventTypesProvider`'s "fetched once, cached, invalidated on write" pattern) → `AsyncValue<List<String>>`.

- [ ] **Step 1: Write the fake**

```dart
// test/core/employees/fakes/fake_employee_ledger_entry_repository.dart
import 'package:crs_ops/core/employees/repositories/employee_ledger_entry_repository.dart';

class FakeEmployeeLedgerEntryRepository implements EmployeeLedgerEntryRepository {
  FakeEmployeeLedgerEntryRepository({List<String>? entryTypesSeed})
      : _entryTypes = List.of(entryTypesSeed ?? const ['advance', 'salary_payment']);

  final List<String> _entryTypes;
  final List<Map<String, Object?>> addedEntries = [];

  @override
  Future<void> addEntry({
    required String employeeId,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  }) async {
    addedEntries.add({
      'employeeId': employeeId,
      'entryDate': entryDate,
      'amount': amount,
      'entryType': entryType,
      'note': note,
    });
    if (!_entryTypes.contains(entryType)) {
      _entryTypes
        ..add(entryType)
        ..sort();
    }
  }

  @override
  Future<List<String>> fetchDistinctEntryTypes() async => List.of(_entryTypes);
}
```

- [ ] **Step 2: Add the providers**

```dart
// lib/core/employees/providers/employee_providers.dart — add these imports and providers
// (append to the existing file; do not remove any existing provider)
```

Add to the top imports:

```dart
import '../repositories/employee_ledger_entry_repository.dart';
```

Add alongside the other repository providers:

```dart
@Riverpod(keepAlive: true)
EmployeeLedgerEntryRepository employeeLedgerEntryRepository(Ref ref) =>
    SupabaseEmployeeLedgerEntryRepository(ref.watch(supabaseClientProvider));
```

Add alongside `eventTypesProvider`:

```dart
@Riverpod(keepAlive: true)
Future<List<String>> distinctEntryTypes(Ref ref) =>
    ref.watch(employeeLedgerEntryRepositoryProvider).fetchDistinctEntryTypes();
```

- [ ] **Step 3: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/employees/providers/ test/core/employees/fakes/fake_employee_ledger_entry_repository.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/employees/providers/employee_providers.dart lib/core/employees/providers/employee_providers.g.dart test/core/employees/fakes/fake_employee_ledger_entry_repository.dart
git commit -m "feat: employeeLedgerEntryRepository/distinctEntryTypes providers + fake"
```

---

### Task 5: "Add payment" dialog

**Files:**
- Create: `lib/core/employees/pages/widgets/add_payment_dialog.dart`
- Modify: `lib/core/employees/pages/employee_detail_page.dart` (add the trigger)
- Modify: `test/core/employees/pages/employee_detail_page_test.dart` (add a case)

**Interfaces:**
- Consumes: `distinctEntryTypesProvider`, `employeeLedgerEntryRepositoryProvider` (Task 4), `employeeTimelineProvider` (Phase 2).
- Produces: `Future<void> showAddPaymentDialog(BuildContext context, WidgetRef ref, String employeeId)`.

- [ ] **Step 1: Write the failing widget test** (appended to the existing file from Phase 2 — do not remove its two existing tests)

```dart
// test/core/employees/pages/employee_detail_page_test.dart — add this test to the existing file
// (add this import alongside the existing ones at the top)
// import '../fakes/fake_employee_ledger_entry_repository.dart';
// import 'package:crs_ops/core/employees/providers/employee_providers.dart'; // already imported

// add inside the existing `void main() { ... }` block, alongside the two existing tests:
  testWidgets('Add payment button opens a dialog that records a new ledger entry', (tester) async {
    final ledgerRepo = FakeEmployeeLedgerEntryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1))]),
          ),
          employeeEventRepositoryProvider.overrideWithValue(FakeEmployeeEventRepository()),
          eventTypeRepositoryProvider.overrideWithValue(FakeEventTypeRepository()),
          employeeLedgerEntryRepositoryProvider.overrideWithValue(ledgerRepo),
        ],
        child: const MaterialApp(home: EmployeeDetailPage(employeeId: '1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-payment-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-payment-dialog')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('payment-amount-field')), '5000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('payment-save-button')));
    await tester.pumpAndSettle();

    expect(ledgerRepo.addedEntries, hasLength(1));
    expect(ledgerRepo.addedEntries.first['amount'], 5000.0);
  });
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/pages/employee_detail_page_test.dart
```

Expected: FAIL — `add-payment-button` doesn't exist yet.

- [ ] **Step 3: Write the dialog**

```dart
// lib/core/employees/pages/widgets/add_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/employee_providers.dart';

Future<void> showAddPaymentDialog(BuildContext context, WidgetRef ref, String employeeId) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AddPaymentDialog(employeeId: employeeId),
  );
}

class _AddPaymentDialog extends ConsumerStatefulWidget {
  const _AddPaymentDialog({required this.employeeId});
  final String employeeId;

  @override
  ConsumerState<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<_AddPaymentDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _newTypeController = TextEditingController();
  String? _selectedType;
  bool _typingNewType = false;
  DateTime _entryDate = DateTime.now();

  bool get _canSave => double.tryParse(_amountController.text) != null;

  Future<void> _save() async {
    final amount = double.parse(_amountController.text);
    final entryType = _typingNewType ? _newTypeController.text : _selectedType;
    if (entryType == null || entryType.isEmpty || entryType == '__new__') return;

    await ref.read(employeeLedgerEntryRepositoryProvider).addEntry(
          employeeId: widget.employeeId,
          entryDate: _entryDate,
          amount: amount,
          entryType: entryType,
        );
    ref.invalidate(distinctEntryTypesProvider);
    ref.invalidate(employeeTimelineProvider(widget.employeeId));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final entryTypesAsync = ref.watch(distinctEntryTypesProvider);

    return AlertDialog(
      key: const Key('add-payment-dialog'),
      title: const Text('Add payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('payment-amount-field'),
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Date: ${_entryDate.toIso8601String().split('T').first}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _entryDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _entryDate = picked);
            },
          ),
          entryTypesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (types) => DropdownButton<String>(
              value: _selectedType,
              hint: const Text('Category (e.g. advance, salary_payment)'),
              items: [
                ...types.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                const DropdownMenuItem(value: '__new__', child: Text('+ New category')),
              ],
              onChanged: (value) => setState(() {
                _typingNewType = value == '__new__';
                _selectedType = value;
              }),
            ),
          ),
          if (_typingNewType)
            TextField(
              controller: _newTypeController,
              decoration: const InputDecoration(labelText: 'New category name'),
            ),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          key: const Key('payment-save-button'),
          onPressed: _canSave ? _save : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
```

*(`_canSave`/`_save` mirror Phase 2's `EmployeeEditPage` pattern exactly — the save button is disabled via a getter checked against the current controller text, until a valid numeric amount exists.)*

- [ ] **Step 4: Wire the trigger into `EmployeeDetailPage`** — add an `AppBar` action (not a second FAB; `Scaffold` only cleanly supports one primary FAB, and the existing "Add event" FAB stays exactly as Phase 2 left it)

```dart
// lib/core/employees/pages/employee_detail_page.dart — modify the AppBar
// add this import: import 'widgets/add_payment_dialog.dart';
// change the AppBar to:
      appBar: AppBar(
        title: employeeAsync.when(
          data: (e) => Text(e.name),
          loading: () => const Text(''),
          error: (_, _) => const Text('Employee'),
        ),
        actions: [
          IconButton(
            key: const Key('add-payment-button'),
            icon: const Icon(Icons.payments),
            tooltip: 'Add payment',
            onPressed: () => showAddPaymentDialog(context, ref, employeeId),
          ),
        ],
      ),
```

- [ ] **Step 5: Run the tests again**

```bash
flutter test test/core/employees/pages/employee_detail_page_test.dart
```

Expected: PASS, 3/3 (the two pre-existing Phase 2 tests plus this task's new one).

- [ ] **Step 6: Commit**

```bash
git add lib/core/employees/pages/widgets/add_payment_dialog.dart lib/core/employees/pages/employee_detail_page.dart test/core/employees/pages/employee_detail_page_test.dart
git commit -m "feat: Add payment dialog, wired into employee detail page"
```

---

### Task 6: Full-phase compile/test sweep + real integration verification

**Files:** none (verification only).

**Interfaces:** none produced; consumes everything from Tasks 1–5.

- [ ] **Step 1: Schema-qualification audit** (the recurring bug from Phases 1–2 — re-checked explicitly every phase since)

```bash
grep -n "\.from(\|\.rpc(" lib/core/employees/repositories/employee_ledger_entry_repository.dart
```

Expected: **2 call sites** (`addEntry`, `fetchDistinctEntryTypes`), both immediately preceded by `.schema('core')`. If either is missing it, fix now and re-run.

- [ ] **Step 2: Run the full analyzer and test suite**

```bash
flutter analyze
flutter test
```

Expected: no errors; all tests pass (Phases 1–3's tests plus this phase's).

- [ ] **Step 3: Real integration check against the live project** — confirm an inserted ledger entry actually appears in `core.employee_timeline` correctly, the exact integration point this phase adds a UI for

```bash
supabase db query --linked "
insert into core.employees (id, name, color) values
  ('77777777-0000-0000-0000-000000000ee', 'Phase4 Ledger Test', 4278238420);
insert into core.employee_ledger_entries (employee_id, entry_date, amount, entry_type, note) values
  ('77777777-0000-0000-0000-000000000ee', '2024-07-01', 5000, 'advance', 'test entry');
select entry_date, kind, label, note from core.employee_timeline
where employee_id = '77777777-0000-0000-0000-000000000ee';
"
```

Expected: one row, `2024-07-01 | ledger | advance | test entry`.

- [ ] **Step 4: Clean up the verification data**

```bash
supabase db query --linked "
delete from core.employee_ledger_entries where employee_id = '77777777-0000-0000-0000-000000000ee';
delete from core.employees where id = '77777777-0000-0000-0000-000000000ee';
"
```

- [ ] **Step 5: Build for web, to verify a real end-to-end compile**

```bash
flutter build web --dart-define=SUPABASE_URL=https://ocalljagckzyvngprlxo.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<from `supabase projects api-keys --project-ref ocalljagckzyvngprlxo`>
```

Expected: `✓ Built build/web`.

- [ ] **Step 6: No commit** — verification only, nothing changes (unless Step 1 found and fixed something, in which case commit that fix first with `fix: schema-qualify missed .from() call in employee_ledger_entry_repository.dart`).

---

## Self-Review

- **Spec coverage**: req. 5 (manual, append-only finance ledger, explicitly not automated payroll) — the ledger entry model/repository/dialog only ever *add* entries, no update/delete method exists anywhere in this plan, matching "append-only" exactly. `entry_type`-as-plain-text-with-dropdown-from-distinct (req. 6's discussion) — Task 3/5. "Add payment" dialog (amount, date, type, note) from the Screens section — Task 5.
- **Placeholder scan**: no `TBD`/`TODO`/`FIXME`. No ambiguous or awkward code left for the executor to "clean up" — the save-button-disabled-until-valid-amount logic is a plain `_canSave` getter, same shape as Phase 2's `EmployeeEditPage`.
- **Type/name consistency**: `EmployeeLedgerEntry` (Task 2) field names match its usage in Task 3's repository. `EmployeeLedgerEntryRepository`'s two method signatures (Task 3) match the fake (Task 4) and the dialog's usage (Task 5) exactly. `employeeLedgerEntryRepositoryProvider`/`distinctEntryTypesProvider` (Task 4) match their usage in Task 5. `employeeTimelineProvider` (Phase 2, unmodified) is invalidated by key `widget.employeeId` matching its family-provider signature exactly, same pattern as Phase 2's `add_event_dialog.dart`.
- **Schema-qualification audit**: 2 call sites in `EmployeeLedgerEntryRepository`, both `.schema('core')`-qualified — verified by direct `grep` while writing this plan (see Task 3's code above), re-verified as an explicit Task 6 checkpoint at execution time.
- **No new migration confirmed, not assumed**: Task 1 exists specifically to re-verify `core.employee_ledger_entries`/`core.employee_timeline` against the actual committed migration file before any code depends on their shape, rather than trusting this plan's own description of them.
- **Existing Phase 2 behavior preserved**: `EmployeeDetailPage`'s "Add event" FAB and its two existing tests are untouched — this phase only adds an `AppBar` action and one new test case to the same file, verified by Task 5 Step 5 expecting all 3 tests (2 old + 1 new) to pass together.

---

**Plan complete and saved to `docs/superpowers/plans/2026-09-20-phase4-finance-ledger.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
