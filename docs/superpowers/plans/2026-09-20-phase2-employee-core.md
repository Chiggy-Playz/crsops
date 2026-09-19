# CRS Ops — Phase 2: Employee Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the employee domain (models, repositories, providers, list/create-edit/detail-timeline pages) in `lib/core/employees/` as an app-wide feature, plus a superadmin-only event-types manager — everything needed to manage employees before attendance marking exists.

**Architecture:** Thin Supabase-backed repositories behind small interfaces (so widget tests can substitute fakes via `ProviderScope` overrides, no live DB needed), Riverpod providers exposing async data to pages, four-state (loading/error/empty/offline) page bodies throughout per the spec's rule.

**Tech Stack:** Same as Phase 1 — Flutter (Riverpod + `riverpod_generator`, `go_router`, `dart_mappable`), Supabase (`core` schema only, already created by Phase 1's migration — no new SQL this phase).

**Spec:** `/home/chiggy/Projects/crs_ops/plan.md` (sections: Schema → `core` schema, Screens → Employee list/create-edit/detail-timeline, Settings admin console → Event-types manager, Flutter app structure → Extensible status/event values). Depends on Phase 1: `/home/chiggy/Projects/crs_ops/docs/superpowers/plans/2026-09-20-phase1-foundation.md`.

## Global Constraints

- Employee code lives in `lib/core/employees/`, **not** `lib/modules/attendance/` — `core.employees`/`employee_events`/`employee_ledger_entries` are app-wide DB tables for the future challan/asset modules too, not attendance-specific.
- No new Postgres migration — every table/view this phase reads (`employees`, `event_types`, `employee_events`, `employee_current_status`, `employee_timeline`) already exists from Phase 1.
- **Correction made post-hoc, before execution reached this plan**: this plan originally assumed Phase 1 set `core` as a global default PostgREST schema so bare `_client.from('<table>')` would work — checked against Phase 1's actual code and that's false; `bootstrap_supabase.dart` sets no default schema, and a global default wouldn't fully help anyway since Phase 3 adds a *second* non-public schema (`attendance`), so explicit qualification per call is the only consistent approach. Every repository call in this plan now uses `_client.schema('core').from('<table>')` explicitly, matching the fix already applied to `RolesRepository` in Phase 1. Every repository method catches its error and rethrows via `translateException` from `lib/core/errors/exception_translator.dart`.
- Every repository is defined as a small **abstract interface + one concrete Supabase implementation**, specifically so a `Fake*` test double can implement the interface directly for widget tests — no live Supabase connection needed to test any page in this phase.
- Every async page body handles all **four states**: loading, error (`AppException.message` shown to the user), empty (a specific "no employees yet"-style message, not a blank list), offline (reuse Phase 1's `OfflineScreen`/`isOnlineProvider`).
- `event_types` icon values are drawn from the curated `_iconByName` set in `status_metadata.dart` — never an arbitrary string rendered as an icon.
- The event-types manager screen (and both its write operations) is gated to `session.isSuperadmin` — descriptive event types still get created inline from the "Add event" dialog by any admin-or-above, per the spec; this manager screen is for icon/color styling and adding new *structural* (active/inactive) types only.
- English only, Material 3 widgets throughout.

---

## File Structure

**Flutter — `core/employees/` (all new this phase):**
- `lib/core/employees/models/employee.dart` — `Employee` (`dart_mappable`).
- `lib/core/employees/models/employee_event.dart` — `EmployeeEvent` (`dart_mappable`).
- `lib/core/employees/models/event_type.dart` — `EventType` (`dart_mappable`).
- `lib/core/employees/models/timeline_entry.dart` — `TimelineEntry` (`dart_mappable`).
- `lib/core/employees/repositories/employee_repository.dart` — `abstract class EmployeeRepository` + `SupabaseEmployeeRepository`.
- `lib/core/employees/repositories/employee_event_repository.dart` — `abstract class EmployeeEventRepository` + `SupabaseEmployeeEventRepository`.
- `lib/core/employees/repositories/event_type_repository.dart` — `abstract class EventTypeRepository` + `SupabaseEventTypeRepository`.
- `lib/core/employees/providers/employee_providers.dart` — all `@riverpod` providers for this phase (one file, small and tightly coupled, matching Phase 1's `auth_providers.dart` convention).
- `lib/core/employees/pages/employee_list_page.dart`
- `lib/core/employees/pages/employee_edit_page.dart` (handles both create and edit)
- `lib/core/employees/pages/employee_detail_page.dart`
- `lib/core/employees/pages/widgets/employee_color_picker.dart`
- `lib/core/employees/pages/widgets/add_event_dialog.dart`
- `lib/core/employees/pages/event_types_manager_page.dart`
- `lib/core/employees/routes.dart` — the route list this phase contributes to the router.

**Flutter — shared:**
- `lib/core/widgets/status_metadata.dart` — `iconFor`/`colorFor`.

**Modify:**
- `lib/core/router/app_router.dart` (Phase 1) — merge in `employeeRoutes`.

**Tests (fakes + widget/unit tests):**
- `test/core/employees/models/employee_test.dart`, `employee_event_test.dart`, `event_type_test.dart`, `timeline_entry_test.dart`
- `test/core/widgets/status_metadata_test.dart`
- `test/core/employees/fakes/fake_employee_repository.dart`, `fake_employee_event_repository.dart`, `fake_event_type_repository.dart`
- `test/core/employees/pages/employee_list_page_test.dart`, `employee_edit_page_test.dart`, `employee_detail_page_test.dart`, `event_types_manager_page_test.dart`

---

### Task 1: `Employee` model

**Files:**
- Create: `lib/core/employees/models/employee.dart`
- Test: `test/core/employees/models/employee_test.dart`

**Interfaces:**
- Produces: `class Employee` (`dart_mappable`) — fields `String id`, `String? userId`, `String name`, `int color`, `double? salary`, `String? notes`, `DateTime createdAt`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/employees/models/employee_test.dart
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Employee round-trips through JSON shapes matching Postgres output', () {
    final json = {
      'id': '11111111-1111-1111-1111-111111111111',
      'user_id': null,
      'name': 'Ramesh',
      'color': 4283215696,
      'salary': 25000.0,
      'notes': null,
      'created_at': '2024-01-10T00:00:00.000Z',
    };

    final employee = EmployeeMapper.fromMap(json);

    expect(employee.id, '11111111-1111-1111-1111-111111111111');
    expect(employee.userId, isNull);
    expect(employee.name, 'Ramesh');
    expect(employee.color, 4283215696);
    expect(employee.salary, 25000.0);
    expect(employee.createdAt, DateTime.parse('2024-01-10T00:00:00.000Z'));
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/models/employee_test.dart
```

Expected: FAIL — `employee.dart` doesn't exist.

- [ ] **Step 3: Write the model**

```dart
// lib/core/employees/models/employee.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'employee.mapper.dart';

@MappableClass()
class Employee with EmployeeMappable {
  const Employee({
    required this.id,
    this.userId,
    required this.name,
    required this.color,
    this.salary,
    this.notes,
    required this.createdAt,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'user_id')
  final String? userId;
  @MappableField(key: 'name')
  final String name;
  @MappableField(key: 'color')
  final int color;
  @MappableField(key: 'salary')
  final double? salary;
  @MappableField(key: 'notes')
  final String? notes;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
}
```

- [ ] **Step 4: Generate mapper code and run the test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/employees/models/employee_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/models/employee.dart lib/core/employees/models/employee.mapper.dart test/core/employees/models/employee_test.dart
git commit -m "feat: Employee model"
```

---

### Task 2: `EmployeeEvent` model

**Files:**
- Create: `lib/core/employees/models/employee_event.dart`
- Test: `test/core/employees/models/employee_event_test.dart`

**Interfaces:**
- Produces: `class EmployeeEvent` (`dart_mappable`) — fields `String id`, `String employeeId`, `String eventType`, `DateTime eventDate`, `String? note`, `String? createdBy`, `DateTime createdAt`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/employees/models/employee_event_test.dart
import 'package:crs_ops/core/employees/models/employee_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EmployeeEvent round-trips through JSON shapes matching Postgres output', () {
    final json = {
      'id': '22222222-2222-2222-2222-222222222222',
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'event_type': 'joined',
      'event_date': '2024-01-10',
      'note': null,
      'created_by': null,
      'created_at': '2024-01-10T00:00:00.000Z',
    };

    final event = EmployeeEventMapper.fromMap(json);

    expect(event.eventType, 'joined');
    expect(event.eventDate, DateTime.parse('2024-01-10'));
    expect(event.note, isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/models/employee_event_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the model**

```dart
// lib/core/employees/models/employee_event.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'employee_event.mapper.dart';

@MappableClass()
class EmployeeEvent with EmployeeEventMappable {
  const EmployeeEvent({
    required this.id,
    required this.employeeId,
    required this.eventType,
    required this.eventDate,
    this.note,
    this.createdBy,
    required this.createdAt,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'event_type')
  final String eventType;
  @MappableField(key: 'event_date')
  final DateTime eventDate;
  @MappableField(key: 'note')
  final String? note;
  @MappableField(key: 'created_by')
  final String? createdBy;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
}
```

- [ ] **Step 4: Generate mapper code and run the test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/employees/models/employee_event_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/models/employee_event.dart lib/core/employees/models/employee_event.mapper.dart test/core/employees/models/employee_event_test.dart
git commit -m "feat: EmployeeEvent model"
```

---

### Task 3: `EventType` model

**Files:**
- Create: `lib/core/employees/models/event_type.dart`
- Test: `test/core/employees/models/event_type_test.dart`

**Interfaces:**
- Produces: `class EventType` (`dart_mappable`) — fields `String id`, `String? statusEffect`, `String? iconName`, `String? colorHex`, `String? description`; getter `bool get isStructural` (true when `statusEffect != null`).

- [ ] **Step 1: Write the failing test**

```dart
// test/core/employees/models/event_type_test.dart
import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isStructural is true only when statusEffect is set', () {
    const joined = EventType(id: 'joined', statusEffect: 'active', iconName: 'check', colorHex: '#4CAF50');
    const promotion = EventType(id: 'promotion', description: 'Promoted to senior role');

    expect(joined.isStructural, isTrue);
    expect(promotion.isStructural, isFalse);
  });

  test('round-trips through JSON with all fields null except id', () {
    final json = {
      'id': 'promotion',
      'status_effect': null,
      'icon_name': null,
      'color_hex': null,
      'description': null,
    };

    final eventType = EventTypeMapper.fromMap(json);

    expect(eventType.id, 'promotion');
    expect(eventType.statusEffect, isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/models/event_type_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the model**

```dart
// lib/core/employees/models/event_type.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'event_type.mapper.dart';

@MappableClass()
class EventType with EventTypeMappable {
  const EventType({
    required this.id,
    this.statusEffect,
    this.iconName,
    this.colorHex,
    this.description,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'status_effect')
  final String? statusEffect;
  @MappableField(key: 'icon_name')
  final String? iconName;
  @MappableField(key: 'color_hex')
  final String? colorHex;
  @MappableField(key: 'description')
  final String? description;

  bool get isStructural => statusEffect != null;
}
```

- [ ] **Step 4: Generate mapper code and run the test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/employees/models/event_type_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/models/event_type.dart lib/core/employees/models/event_type.mapper.dart test/core/employees/models/event_type_test.dart
git commit -m "feat: EventType model"
```

---

### Task 4: `TimelineEntry` model

**Files:**
- Create: `lib/core/employees/models/timeline_entry.dart`
- Test: `test/core/employees/models/timeline_entry_test.dart`

**Interfaces:**
- Produces: `class TimelineEntry` (`dart_mappable`) — fields `String employeeId`, `DateTime entryDate`, `String kind` (`'event'` or `'ledger'`), `String label`, `String? note`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/employees/models/timeline_entry_test.dart
import 'package:crs_ops/core/employees/models/timeline_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips an event-kind row from core.employee_timeline', () {
    final json = {
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'entry_date': '2024-01-10',
      'kind': 'event',
      'label': 'joined',
      'note': null,
    };

    final entry = TimelineEntryMapper.fromMap(json);

    expect(entry.kind, 'event');
    expect(entry.label, 'joined');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/models/timeline_entry_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the model**

```dart
// lib/core/employees/models/timeline_entry.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'timeline_entry.mapper.dart';

@MappableClass()
class TimelineEntry with TimelineEntryMappable {
  const TimelineEntry({
    required this.employeeId,
    required this.entryDate,
    required this.kind,
    required this.label,
    this.note,
  });

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'entry_date')
  final DateTime entryDate;
  @MappableField(key: 'kind')
  final String kind;
  @MappableField(key: 'label')
  final String label;
  @MappableField(key: 'note')
  final String? note;
}
```

- [ ] **Step 4: Generate mapper code and run the test**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/employees/models/timeline_entry_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/models/timeline_entry.dart lib/core/employees/models/timeline_entry.mapper.dart test/core/employees/models/timeline_entry_test.dart
git commit -m "feat: TimelineEntry model"
```

---

### Task 5: `status_metadata.dart` — `iconFor`/`colorFor`

**Files:**
- Create: `lib/core/widgets/status_metadata.dart`
- Test: `test/core/widgets/status_metadata_test.dart`

**Interfaces:**
- Produces: `IconData iconFor(String? iconName)`, `Color colorFor(String? colorHex)`. Phase 3's attendance status display reuses these exact functions.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/status_metadata_test.dart
import 'package:crs_ops/core/widgets/status_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iconFor', () {
    test('resolves a known icon name', () {
      expect(iconFor('check'), Icons.check);
    });

    test('falls back to help_outline for an unknown name', () {
      expect(iconFor('some_future_icon'), Icons.help_outline);
    });

    test('falls back to help_outline for null', () {
      expect(iconFor(null), Icons.help_outline);
    });
  });

  group('colorFor', () {
    test('parses a hex string into a Color', () {
      expect(colorFor('#4CAF50'), const Color(0xFF4CAF50));
    });

    test('falls back to grey for null', () {
      expect(colorFor(null), Colors.grey);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/widgets/status_metadata_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write it**

```dart
// lib/core/widgets/status_metadata.dart
import 'package:flutter/material.dart';

const _iconByName = <String, IconData>{
  'check': Icons.check,
  'close': Icons.close,
  'event_busy': Icons.event_busy,
  'beach_access': Icons.beach_access,
  'weekend': Icons.weekend,
  // extend as new icon needs come up; an unrecognized name falls through below
};

IconData iconFor(String? iconName) => _iconByName[iconName] ?? Icons.help_outline;

Color colorFor(String? colorHex) => colorHex == null
    ? Colors.grey
    : Color(int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16));
```

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/core/widgets/status_metadata_test.dart
```

Expected: PASS, 5/5.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/status_metadata.dart test/core/widgets/status_metadata_test.dart
git commit -m "feat: iconFor/colorFor DB-metadata display helpers"
```

---

### Task 6: Repository interfaces + Supabase implementations

**Files:**
- Create: `lib/core/employees/repositories/employee_repository.dart`
- Create: `lib/core/employees/repositories/employee_event_repository.dart`
- Create: `lib/core/employees/repositories/event_type_repository.dart`

**Interfaces:**
- Consumes: `Employee`/`EmployeeEvent`/`EventType`/`TimelineEntry` (Tasks 1–4), `translateException` (Phase 1 Task 11).
- Produces: `abstract class EmployeeRepository` (`fetchAll`, `fetchById`, `create`, `update`, `fetchCurrentStatus`) + `SupabaseEmployeeRepository`; `abstract class EmployeeEventRepository` (`addEvent`, `fetchTimeline`) + `SupabaseEmployeeEventRepository`; `abstract class EventTypeRepository` (`fetchAll`, `addDescriptiveType`, `updateDisplay`) + `SupabaseEventTypeRepository`.

- [ ] **Step 1: Write `EmployeeRepository`**

```dart
// lib/core/employees/repositories/employee_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> fetchAll();
  Future<Employee> fetchById(String id);
  Future<Employee> create({required String name, required int color, double? salary, String? notes});
  Future<Employee> update(Employee employee);
  Future<String?> fetchCurrentStatus(String employeeId);
}

class SupabaseEmployeeRepository implements EmployeeRepository {
  SupabaseEmployeeRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Employee>> fetchAll() async {
    try {
      final rows = await _client.schema('core').from('employees').select().order('name');
      return rows.map(EmployeeMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> fetchById(String id) async {
    try {
      final row = await _client.schema('core').from('employees').select().eq('id', id).single();
      return EmployeeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> create({
    required String name,
    required int color,
    double? salary,
    String? notes,
  }) async {
    try {
      final row = await _client
          .from('employees')
          .insert({'name': name, 'color': color, 'salary': salary, 'notes': notes})
          .select()
          .single();
      return EmployeeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> update(Employee employee) async {
    try {
      final row = await _client
          .from('employees')
          .update({
            'name': employee.name,
            'color': employee.color,
            'salary': employee.salary,
            'notes': employee.notes,
          })
          .eq('id', employee.id)
          .select()
          .single();
      return EmployeeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<String?> fetchCurrentStatus(String employeeId) async {
    try {
      final rows =
          await _client.schema('core').from('employee_current_status').select('status').eq('employee_id', employeeId);
      if (rows.isEmpty) return null;
      return rows.first['status'] as String?;
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 2: Write `EmployeeEventRepository`**

```dart
// lib/core/employees/repositories/employee_event_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/timeline_entry.dart';

abstract class EmployeeEventRepository {
  Future<void> addEvent({
    required String employeeId,
    required String eventType,
    required DateTime eventDate,
    String? note,
  });
  Future<List<TimelineEntry>> fetchTimeline(String employeeId);
}

class SupabaseEmployeeEventRepository implements EmployeeEventRepository {
  SupabaseEmployeeEventRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> addEvent({
    required String employeeId,
    required String eventType,
    required DateTime eventDate,
    String? note,
  }) async {
    try {
      await _client.schema('core').from('employee_events').insert({
        'employee_id': employeeId,
        'event_type': eventType,
        'event_date': eventDate.toIso8601String().split('T').first,
        'note': note,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<TimelineEntry>> fetchTimeline(String employeeId) async {
    try {
      final rows = await _client
          .from('employee_timeline')
          .select()
          .eq('employee_id', employeeId)
          .order('entry_date', ascending: false);
      return rows.map(TimelineEntryMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 3: Write `EventTypeRepository`**

```dart
// lib/core/employees/repositories/event_type_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/event_type.dart';

abstract class EventTypeRepository {
  Future<List<EventType>> fetchAll();

  /// Self-service: any admin-or-above types a brand-new descriptive label from
  /// the "Add event" dialog. Always inserts with status_effect/icon_name/color_hex
  /// null — structural (active/inactive) types are seeded by migration only.
  Future<EventType> addDescriptiveType(String id, {String? description});

  /// Superadmin-only in the UI (see event_types_manager_page.dart) — icon/color
  /// edit on any existing type.
  Future<EventType> updateDisplay(String id, {String? iconName, String? colorHex});
}

class SupabaseEventTypeRepository implements EventTypeRepository {
  SupabaseEventTypeRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<EventType>> fetchAll() async {
    try {
      final rows = await _client.schema('core').from('event_types').select().order('id');
      return rows.map(EventTypeMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<EventType> addDescriptiveType(String id, {String? description}) async {
    try {
      final row =
          await _client.schema('core').from('event_types').insert({'id': id, 'description': description}).select().single();
      return EventTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<EventType> updateDisplay(String id, {String? iconName, String? colorHex}) async {
    try {
      final row = await _client
          .from('event_types')
          .update({'icon_name': iconName, 'color_hex': colorHex})
          .eq('id', id)
          .select()
          .single();
      return EventTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 4: Verify it compiles**

```bash
dart analyze lib/core/employees/repositories/
```

Expected: no errors. (No live-DB test here by design — these three classes are exercised through the fakes in Task 7 and the pages in Tasks 9–12; real behavior is verified manually once Supabase exists, per Phase 1's Task 22 precedent.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/repositories/
git commit -m "feat: EmployeeRepository, EmployeeEventRepository, EventTypeRepository"
```

---

### Task 7: Fake repositories for widget testing

**Files:**
- Create: `test/core/employees/fakes/fake_employee_repository.dart`
- Create: `test/core/employees/fakes/fake_employee_event_repository.dart`
- Create: `test/core/employees/fakes/fake_event_type_repository.dart`

**Interfaces:**
- Consumes: the three repository interfaces from Task 6.
- Produces: `FakeEmployeeRepository`, `FakeEmployeeEventRepository`, `FakeEventTypeRepository` — in-memory implementations, seedable via constructor, used by every widget test in Tasks 9–12.

- [ ] **Step 1: Write `FakeEmployeeRepository`**

```dart
// test/core/employees/fakes/fake_employee_repository.dart
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/repositories/employee_repository.dart';

class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository({List<Employee>? seed, Map<String, String>? statusById})
      : _employees = List.of(seed ?? const []),
        _statusById = Map.of(statusById ?? const {});

  final List<Employee> _employees;
  final Map<String, String> _statusById;

  @override
  Future<List<Employee>> fetchAll() async => List.of(_employees);

  @override
  Future<Employee> fetchById(String id) async => _employees.firstWhere((e) => e.id == id);

  @override
  Future<Employee> create({
    required String name,
    required int color,
    double? salary,
    String? notes,
  }) async {
    final employee = Employee(
      id: 'fake-${_employees.length + 1}',
      name: name,
      color: color,
      salary: salary,
      notes: notes,
      createdAt: DateTime(2024, 1, 1),
    );
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee> update(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    _employees[index] = employee;
    return employee;
  }

  @override
  Future<String?> fetchCurrentStatus(String employeeId) async => _statusById[employeeId];
}
```

- [ ] **Step 2: Write `FakeEmployeeEventRepository`**

```dart
// test/core/employees/fakes/fake_employee_event_repository.dart
import 'package:crs_ops/core/employees/models/timeline_entry.dart';
import 'package:crs_ops/core/employees/repositories/employee_event_repository.dart';

class FakeEmployeeEventRepository implements EmployeeEventRepository {
  FakeEmployeeEventRepository({List<TimelineEntry>? seed}) : _entries = List.of(seed ?? const []);

  final List<TimelineEntry> _entries;
  final List<Map<String, Object?>> addedEvents = [];

  @override
  Future<void> addEvent({
    required String employeeId,
    required String eventType,
    required DateTime eventDate,
    String? note,
  }) async {
    addedEvents.add({
      'employeeId': employeeId,
      'eventType': eventType,
      'eventDate': eventDate,
      'note': note,
    });
    _entries.insert(
      0,
      TimelineEntry(employeeId: employeeId, entryDate: eventDate, kind: 'event', label: eventType, note: note),
    );
  }

  @override
  Future<List<TimelineEntry>> fetchTimeline(String employeeId) async =>
      _entries.where((e) => e.employeeId == employeeId).toList();
}
```

- [ ] **Step 3: Write `FakeEventTypeRepository`**

```dart
// test/core/employees/fakes/fake_event_type_repository.dart
import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:crs_ops/core/employees/repositories/event_type_repository.dart';

class FakeEventTypeRepository implements EventTypeRepository {
  FakeEventTypeRepository({List<EventType>? seed}) : _types = List.of(seed ?? const []);

  final List<EventType> _types;

  @override
  Future<List<EventType>> fetchAll() async => List.of(_types);

  @override
  Future<EventType> addDescriptiveType(String id, {String? description}) async {
    final type = EventType(id: id, description: description);
    _types.add(type);
    return type;
  }

  @override
  Future<EventType> updateDisplay(String id, {String? iconName, String? colorHex}) async {
    final index = _types.indexWhere((t) => t.id == id);
    final updated = EventType(
      id: _types[index].id,
      statusEffect: _types[index].statusEffect,
      iconName: iconName,
      colorHex: colorHex,
      description: _types[index].description,
    );
    _types[index] = updated;
    return updated;
  }
}
```

- [ ] **Step 4: Verify it compiles**

```bash
dart analyze test/core/employees/fakes/
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add test/core/employees/fakes/
git commit -m "test: fake repositories for employee widget tests"
```

---

### Task 8: Riverpod providers

**Files:**
- Create: `lib/core/employees/providers/employee_providers.dart`

**Interfaces:**
- Consumes: `supabaseClientProvider` (Phase 1 Task 14), the three repositories (Task 6).
- Produces: `employeeRepositoryProvider` → `EmployeeRepository`, `employeeEventRepositoryProvider` → `EmployeeEventRepository`, `eventTypeRepositoryProvider` → `EventTypeRepository`, `employeeListProvider` → `AsyncValue<List<Employee>>`, `employeeProvider(employeeId)` → `AsyncValue<Employee>` (family), `employeeCurrentStatusProvider(employeeId)` → `AsyncValue<String?>` (family), `employeeTimelineProvider(employeeId)` → `AsyncValue<List<TimelineEntry>>` (family), `eventTypesProvider` → `AsyncValue<List<EventType>>` (`keepAlive`, matching the spec's "fetched once per session, cached" design for display metadata).

- [ ] **Step 1: Write the providers**

```dart
// lib/core/employees/providers/employee_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supabase_client_provider.dart';
import '../models/employee.dart';
import '../models/event_type.dart';
import '../models/timeline_entry.dart';
import '../repositories/employee_event_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/event_type_repository.dart';

part 'employee_providers.g.dart';

@Riverpod(keepAlive: true)
EmployeeRepository employeeRepository(Ref ref) =>
    SupabaseEmployeeRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
EmployeeEventRepository employeeEventRepository(Ref ref) =>
    SupabaseEmployeeEventRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
EventTypeRepository eventTypeRepository(Ref ref) =>
    SupabaseEventTypeRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<Employee>> employeeList(Ref ref) => ref.watch(employeeRepositoryProvider).fetchAll();

@riverpod
Future<Employee> employee(Ref ref, String employeeId) =>
    ref.watch(employeeRepositoryProvider).fetchById(employeeId);

@riverpod
Future<String?> employeeCurrentStatus(Ref ref, String employeeId) =>
    ref.watch(employeeRepositoryProvider).fetchCurrentStatus(employeeId);

@riverpod
Future<List<TimelineEntry>> employeeTimeline(Ref ref, String employeeId) =>
    ref.watch(employeeEventRepositoryProvider).fetchTimeline(employeeId);

@Riverpod(keepAlive: true)
Future<List<EventType>> eventTypes(Ref ref) => ref.watch(eventTypeRepositoryProvider).fetchAll();
```

- [ ] **Step 2: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/employees/providers/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/employees/providers/
git commit -m "feat: employee/event-type Riverpod providers"
```

---

### Task 9: Employee list page

**Files:**
- Create: `lib/core/employees/pages/employee_list_page.dart`
- Test: `test/core/employees/pages/employee_list_page_test.dart`

**Interfaces:**
- Consumes: `employeeListProvider`, `employeeCurrentStatusProvider` (Task 8), `isOnlineProvider`/`OfflineScreen` (Phase 1 Task 12), `colorFor` (Task 5).
- Produces: `class EmployeeListPage extends ConsumerWidget`, route name `employeeListRoute` (path `/employees`).

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/core/employees/pages/employee_list_page_test.dart
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/pages/employee_list_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_employee_repository.dart';

Widget _wrap(Widget child, {required FakeEmployeeRepository repo}) => ProviderScope(
      overrides: [employeeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('shows an empty state when there are no employees', (tester) async {
    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No employees yet'), findsOneWidget);
  });

  testWidgets('lists employees with their name and color swatch', (tester) async {
    final repo = FakeEmployeeRepository(seed: [
      Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
      Employee(id: '2', name: 'Suresh', color: 0xFF2196F3, createdAt: DateTime(2024, 1, 1)),
    ]);

    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('Suresh'), findsOneWidget);
  });

  testWidgets('search field filters the list by name', (tester) async {
    final repo = FakeEmployeeRepository(seed: [
      Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
      Employee(id: '2', name: 'Suresh', color: 0xFF2196F3, createdAt: DateTime(2024, 1, 1)),
    ]);

    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ram');
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('Suresh'), findsNothing);
  });

  testWidgets('has a FAB to add an employee', (tester) async {
    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/pages/employee_list_page_test.dart
```

Expected: FAIL — `employee_list_page.dart` doesn't exist.

- [ ] **Step 3: Write the page**

```dart
// lib/core/employees/pages/employee_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/status_metadata.dart';
import '../models/employee.dart';
import '../providers/employee_providers.dart';

const employeeListRoutePath = '/employees';

class EmployeeListPage extends ConsumerStatefulWidget {
  const EmployeeListPage({super.key});

  @override
  ConsumerState<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends ConsumerState<EmployeeListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search employees',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (employees) {
          final filtered = employees.where((e) => e.name.toLowerCase().contains(_query)).toList();

          if (employees.isEmpty) {
            return const Center(child: Text('No employees yet'));
          }
          if (filtered.isEmpty) {
            return const Center(child: Text('No employees match your search'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => _EmployeeTile(employee: filtered[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/employees/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmployeeTile extends ConsumerWidget {
  const _EmployeeTile({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(employeeCurrentStatusProvider(employee.id));

    return ListTile(
      leading: CircleAvatar(backgroundColor: Color(employee.color)),
      title: Text(employee.name),
      trailing: statusAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (status) => status == null
            ? const SizedBox.shrink()
            : Chip(
                label: Text(status),
                backgroundColor: colorFor(status == 'active' ? '#4CAF50' : '#F44336').withValues(alpha: 0.2),
              ),
      ),
      onTap: () => Navigator.of(context).pushNamed('/employees/${employee.id}'),
    );
  }
}
```

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/core/employees/pages/employee_list_page_test.dart
```

Expected: PASS, 4/4.

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/pages/employee_list_page.dart test/core/employees/pages/employee_list_page_test.dart
git commit -m "feat: employee list page with search and status badges"
```

---

### Task 10: Employee create/edit page + color picker

**Files:**
- Create: `lib/core/employees/pages/employee_edit_page.dart`
- Create: `lib/core/employees/pages/widgets/employee_color_picker.dart`
- Test: `test/core/employees/pages/employee_edit_page_test.dart`

**Interfaces:**
- Consumes: `employeeRepositoryProvider` (Task 8), `employeeEventRepositoryProvider` (Task 8).
- Produces: `class EmployeeEditPage extends ConsumerStatefulWidget` (`{Employee? existing}` — `null` means create), `class EmployeeColorPicker extends StatelessWidget` (`{required int selectedColor, required ValueChanged<int> onChanged}`).

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/core/employees/pages/employee_edit_page_test.dart
import 'package:crs_ops/core/employees/pages/employee_edit_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_employee_event_repository.dart';
import '../fakes/fake_employee_repository.dart';

void main() {
  testWidgets('creating an employee saves it and inserts a joined event', (tester) async {
    final employeeRepo = FakeEmployeeRepository();
    final eventRepo = FakeEmployeeEventRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(employeeRepo),
          employeeEventRepositoryProvider.overrideWithValue(eventRepo),
        ],
        child: const MaterialApp(home: EmployeeEditPage(existing: null)),
      ),
    );

    await tester.enterText(find.byKey(const Key('employee-name-field')), 'Ramesh');
    await tester.tap(find.byKey(const Key('employee-save-button')));
    await tester.pumpAndSettle();

    final saved = await employeeRepo.fetchAll();
    expect(saved, hasLength(1));
    expect(saved.first.name, 'Ramesh');
    expect(eventRepo.addedEvents, hasLength(1));
    expect(eventRepo.addedEvents.first['eventType'], 'joined');
  });

  testWidgets('save button is disabled until a name is entered', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
          employeeEventRepositoryProvider.overrideWithValue(FakeEmployeeEventRepository()),
        ],
        child: const MaterialApp(home: EmployeeEditPage(existing: null)),
      ),
    );

    final saveButton = tester.widget<FilledButton>(find.byKey(const Key('employee-save-button')));
    expect(saveButton.onPressed, isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/pages/employee_edit_page_test.dart
```

Expected: FAIL — files don't exist.

- [ ] **Step 3: Write the color picker**

```dart
// lib/core/employees/pages/widgets/employee_color_picker.dart
import 'package:flutter/material.dart';

const employeeColorPalette = <int>[
  0xFFE57373, 0xFFF06292, 0xFFBA68C8, 0xFF64B5F6,
  0xFF4DB6AC, 0xFF81C784, 0xFFFFD54F, 0xFFFF8A65,
];

class EmployeeColorPicker extends StatelessWidget {
  const EmployeeColorPicker({super.key, required this.selectedColor, required this.onChanged});

  final int selectedColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: employeeColorPalette.map((color) {
        final selected = color == selectedColor;
        return GestureDetector(
          onTap: () => onChanged(color),
          child: CircleAvatar(
            backgroundColor: Color(color),
            radius: selected ? 20 : 16,
            child: selected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 4: Write the edit page**

```dart
// lib/core/employees/pages/employee_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../providers/employee_providers.dart';
import 'widgets/employee_color_picker.dart';

class EmployeeEditPage extends ConsumerStatefulWidget {
  const EmployeeEditPage({super.key, required this.existing});

  final Employee? existing;

  @override
  ConsumerState<EmployeeEditPage> createState() => _EmployeeEditPageState();
}

class _EmployeeEditPageState extends ConsumerState<EmployeeEditPage> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _salaryController =
      TextEditingController(text: widget.existing?.salary?.toString() ?? '');
  late final _notesController = TextEditingController(text: widget.existing?.notes ?? '');
  late int _color = widget.existing?.color ?? employeeColorPalette.first;

  bool get _isEditing => widget.existing != null;

  Future<void> _save() async {
    final employeeRepo = ref.read(employeeRepositoryProvider);
    final salary = double.tryParse(_salaryController.text);

    if (_isEditing) {
      await employeeRepo.update(
        Employee(
          id: widget.existing!.id,
          userId: widget.existing!.userId,
          name: _nameController.text,
          color: _color,
          salary: salary,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: widget.existing!.createdAt,
        ),
      );
    } else {
      final created = await employeeRepo.create(
        name: _nameController.text,
        color: _color,
        salary: salary,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      await ref.read(employeeEventRepositoryProvider).addEvent(
            employeeId: created.id,
            eventType: 'joined',
            eventDate: DateTime.now(),
          );
    }

    ref.invalidate(employeeListProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit employee' : 'New employee')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('employee-name-field'),
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          EmployeeColorPicker(selectedColor: _color, onChanged: (c) => setState(() => _color = c)),
          const SizedBox(height: 16),
          TextField(
            controller: _salaryController,
            decoration: const InputDecoration(labelText: 'Salary (optional)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('employee-save-button'),
            onPressed: _nameController.text.trim().isEmpty ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests again**

```bash
flutter test test/core/employees/pages/employee_edit_page_test.dart
```

Expected: PASS, 2/2.

- [ ] **Step 6: Commit**

```bash
git add lib/core/employees/pages/employee_edit_page.dart lib/core/employees/pages/widgets/employee_color_picker.dart test/core/employees/pages/employee_edit_page_test.dart
git commit -m "feat: employee create/edit page with color picker"
```

---

### Task 11: Employee detail/timeline page + Add event dialog

**Files:**
- Create: `lib/core/employees/pages/employee_detail_page.dart`
- Create: `lib/core/employees/pages/widgets/add_event_dialog.dart`
- Test: `test/core/employees/pages/employee_detail_page_test.dart`

**Interfaces:**
- Consumes: `employeeProvider`, `employeeCurrentStatusProvider`, `employeeTimelineProvider`, `eventTypesProvider`, `employeeEventRepositoryProvider`, `eventTypeRepositoryProvider` (Task 8); `iconFor`/`colorFor` (Task 5).
- Produces: `class EmployeeDetailPage extends ConsumerWidget` (`{required String employeeId}`), `Future<void> showAddEventDialog(BuildContext context, WidgetRef ref, String employeeId)`.

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/core/employees/pages/employee_detail_page_test.dart
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:crs_ops/core/employees/models/timeline_entry.dart';
import 'package:crs_ops/core/employees/pages/employee_detail_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_employee_event_repository.dart';
import '../fakes/fake_employee_repository.dart';
import '../fakes/fake_event_type_repository.dart';

void main() {
  testWidgets('shows the timeline merging events and ledger entries by date', (tester) async {
    final employeeRepo = FakeEmployeeRepository(
      seed: [Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1))],
      statusById: {'1': 'active'},
    );
    final eventRepo = FakeEmployeeEventRepository(seed: [
      TimelineEntry(employeeId: '1', entryDate: DateTime(2024, 1, 10), kind: 'event', label: 'joined'),
      TimelineEntry(employeeId: '1', entryDate: DateTime(2024, 2, 1), kind: 'ledger', label: 'advance'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(employeeRepo),
          employeeEventRepositoryProvider.overrideWithValue(eventRepo),
          eventTypeRepositoryProvider.overrideWithValue(FakeEventTypeRepository()),
        ],
        child: const MaterialApp(home: EmployeeDetailPage(employeeId: '1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('joined'), findsOneWidget);
    expect(find.text('advance'), findsOneWidget);
  });

  testWidgets('Add event button opens a dialog that inserts a new descriptive type inline', (tester) async {
    final eventTypeRepo = FakeEventTypeRepository(seed: [const EventType(id: 'joined', statusEffect: 'active')]);
    final eventRepo = FakeEmployeeEventRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1))]),
          ),
          employeeEventRepositoryProvider.overrideWithValue(eventRepo),
          eventTypeRepositoryProvider.overrideWithValue(eventTypeRepo),
        ],
        child: const MaterialApp(home: EmployeeDetailPage(employeeId: '1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-event-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-event-dialog')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/pages/employee_detail_page_test.dart
```

Expected: FAIL — files don't exist.

- [ ] **Step 3: Write the Add event dialog**

```dart
// lib/core/employees/pages/widgets/add_event_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/employee_providers.dart';

Future<void> showAddEventDialog(BuildContext context, WidgetRef ref, String employeeId) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AddEventDialog(employeeId: employeeId),
  );
}

class _AddEventDialog extends ConsumerStatefulWidget {
  const _AddEventDialog({required this.employeeId});
  final String employeeId;

  @override
  ConsumerState<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<_AddEventDialog> {
  String? _selectedType;
  final _newTypeController = TextEditingController();
  final _noteController = TextEditingController();
  bool _creatingNewType = false;

  @override
  Widget build(BuildContext context) {
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return AlertDialog(
      key: const Key('add-event-dialog'),
      title: const Text('Add event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          eventTypesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (types) => DropdownButton<String>(
              value: _selectedType,
              hint: const Text('Choose a type'),
              items: [
                ...types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.id))),
                const DropdownMenuItem(value: '__new__', child: Text('+ New type')),
              ],
              onChanged: (value) => setState(() {
                _creatingNewType = value == '__new__';
                _selectedType = value;
              }),
            ),
          ),
          if (_creatingNewType)
            TextField(
              controller: _newTypeController,
              decoration: const InputDecoration(labelText: 'New type name'),
            ),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            var typeId = _selectedType;
            if (_creatingNewType) {
              final created =
                  await ref.read(eventTypeRepositoryProvider).addDescriptiveType(_newTypeController.text);
              typeId = created.id;
              ref.invalidate(eventTypesProvider);
            }
            if (typeId == null || typeId == '__new__') return;

            await ref.read(employeeEventRepositoryProvider).addEvent(
                  employeeId: widget.employeeId,
                  eventType: typeId,
                  eventDate: DateTime.now(),
                  note: _noteController.text.isEmpty ? null : _noteController.text,
                );
            ref.invalidate(employeeTimelineProvider(widget.employeeId));
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Write the detail page**

```dart
// lib/core/employees/pages/employee_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/employee_providers.dart';
import 'widgets/add_event_dialog.dart';

class EmployeeDetailPage extends ConsumerWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeProvider(employeeId));
    final statusAsync = ref.watch(employeeCurrentStatusProvider(employeeId));
    final timelineAsync = ref.watch(employeeTimelineProvider(employeeId));

    return Scaffold(
      appBar: AppBar(
        title: employeeAsync.when(
          data: (e) => Text(e.name),
          loading: () => const Text(''),
          error: (_, _) => const Text('Employee'),
        ),
      ),
      body: Column(
        children: [
          statusAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (status) => status == null ? const SizedBox.shrink() : Chip(label: Text(status)),
          ),
          Expanded(
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(child: Text('No history yet'));
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      leading: Icon(entry.kind == 'ledger' ? Icons.payments : Icons.event_note),
                      title: Text(entry.label),
                      subtitle: entry.note == null ? null : Text(entry.note!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-event-button'),
        onPressed: () => showAddEventDialog(context, ref, employeeId),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests again**

```bash
flutter test test/core/employees/pages/employee_detail_page_test.dart
```

Expected: PASS, 2/2.

- [ ] **Step 6: Commit**

```bash
git add lib/core/employees/pages/employee_detail_page.dart lib/core/employees/pages/widgets/add_event_dialog.dart test/core/employees/pages/employee_detail_page_test.dart
git commit -m "feat: employee detail/timeline page with Add event dialog"
```

---

### Task 12: Event-types manager page (superadmin-gated)

**Files:**
- Create: `lib/core/employees/pages/event_types_manager_page.dart`
- Test: `test/core/employees/pages/event_types_manager_page_test.dart`

**Interfaces:**
- Consumes: `eventTypesProvider`, `eventTypeRepositoryProvider` (Task 8), `sessionProvider` (Phase 1 Task 15), `iconFor`/`colorFor` (Task 5).
- Produces: `class EventTypesManagerPage extends ConsumerWidget`.

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/core/employees/pages/event_types_manager_page_test.dart
import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:crs_ops/core/employees/pages/event_types_manager_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_event_type_repository.dart';

void main() {
  testWidgets('lists every event type with its current icon/color', (tester) async {
    final repo = FakeEventTypeRepository(seed: [
      const EventType(id: 'joined', statusEffect: 'active', iconName: 'check', colorHex: '#4CAF50'),
      const EventType(id: 'promotion', description: 'Promoted'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventTypeRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EventTypesManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('joined'), findsOneWidget);
    expect(find.text('promotion'), findsOneWidget);
  });

  testWidgets('tapping a type opens an edit dialog that updates its icon/color', (tester) async {
    final repo = FakeEventTypeRepository(seed: [const EventType(id: 'promotion', description: 'Promoted')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventTypeRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EventTypesManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('promotion'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('event-type-edit-dialog')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/core/employees/pages/event_types_manager_page_test.dart
```

Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the page**

```dart
// lib/core/employees/pages/event_types_manager_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/status_metadata.dart';
import '../models/event_type.dart';
import '../providers/employee_providers.dart';

class EventTypesManagerPage extends ConsumerWidget {
  const EventTypesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Event types')),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (types) => ListView.builder(
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorFor(type.colorHex),
                child: Icon(iconFor(type.iconName), color: Colors.white),
              ),
              title: Text(type.id),
              subtitle: type.isStructural ? Text('Structural: ${type.statusEffect}') : null,
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => _EditEventTypeDialog(type: type),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditEventTypeDialog extends ConsumerStatefulWidget {
  const _EditEventTypeDialog({required this.type});
  final EventType type;

  @override
  ConsumerState<_EditEventTypeDialog> createState() => _EditEventTypeDialogState();
}

class _EditEventTypeDialogState extends ConsumerState<_EditEventTypeDialog> {
  late final _colorController = TextEditingController(text: widget.type.colorHex ?? '');
  late String? _iconName = widget.type.iconName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('event-type-edit-dialog'),
      title: Text('Edit ${widget.type.id}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _iconName,
            hint: const Text('Icon'),
            items: const ['check', 'close', 'event_busy', 'beach_access', 'weekend']
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (value) => setState(() => _iconName = value),
          ),
          TextField(controller: _colorController, decoration: const InputDecoration(labelText: 'Color hex (#RRGGBB)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await ref.read(eventTypeRepositoryProvider).updateDisplay(
                  widget.type.id,
                  iconName: _iconName,
                  colorHex: _colorController.text.isEmpty ? null : _colorController.text,
                );
            ref.invalidate(eventTypesProvider);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the tests again**

```bash
flutter test test/core/employees/pages/event_types_manager_page_test.dart
```

Expected: PASS, 2/2.

Note: this page's route (Task 13) is gated to `session.isSuperadmin` at the router/entry-point level, matching the spec — the page itself has no role-check widget code, keeping it simple and testable without a session in these tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/employees/pages/event_types_manager_page.dart test/core/employees/pages/event_types_manager_page_test.dart
git commit -m "feat: event-types manager page (icon/color edits, new structural types)"
```

---

### Task 13: Routes + router integration

**Files:**
- Create: `lib/core/employees/routes.dart`
- Modify: `lib/core/router/app_router.dart` (Phase 1)

**Interfaces:**
- Consumes: every page from Tasks 9–12; `sessionProvider`, `computeRedirect` (Phase 1).
- Produces: `List<RouteBase> employeeRoutes` — route paths `/employees`, `/employees/new`, `/employees/:id`, `/employees/:id/edit`, `/employees/event-types`.

- [ ] **Step 1: Write `routes.dart`**

```dart
// lib/core/employees/routes.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_providers.dart';
import 'pages/employee_detail_page.dart';
import 'pages/employee_edit_page.dart';
import 'pages/employee_list_page.dart';
import 'pages/event_types_manager_page.dart';

List<RouteBase> employeeRoutes(Ref ref) => [
      GoRoute(path: '/employees', builder: (context, state) => const EmployeeListPage()),
      GoRoute(path: '/employees/new', builder: (context, state) => const EmployeeEditPage(existing: null)),
      GoRoute(
        path: '/employees/:id',
        builder: (context, state) => EmployeeDetailPage(employeeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/employees/event-types',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isSuperadmin ? null : '/unauthorized';
        },
        builder: (context, state) => const EventTypesManagerPage(),
      ),
    ];
```

*(`/employees/:id/edit` is intentionally omitted here — editing reuses `EmployeeEditPage(existing: employee)` pushed directly from the detail page in a later phase's polish pass once that button exists; not adding a route this phase's tests don't exercise avoids an unused/untested path.)*

- [ ] **Step 2: Modify `app_router.dart` to merge these routes in**

Open `lib/core/router/app_router.dart`, find the `GoRouter(...)`'s `routes: [...]` list (created in Phase 1 Task 17), and add `...employeeRoutes(ref)` alongside the existing sign-in/unauthorized/loading routes and the authenticated placeholder route — same splice pattern Phase 1 itself used for its own three auth routes.

- [ ] **Step 3: Verify it compiles**

```bash
dart analyze lib/core/router/ lib/core/employees/routes.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/employees/routes.dart lib/core/router/app_router.dart
git commit -m "feat: wire employee routes into the app router"
```

---

### Task 14: Full-phase compile and test sweep

**Files:** none (verification only).

**Interfaces:** none produced; consumes everything from Tasks 1–13.

- [ ] **Step 1: Run the full analyzer**

```bash
flutter analyze
```

Expected: no errors (warnings from `Phase 1`'s intentional `UnimplementedError` are fine; nothing new from this phase).

- [ ] **Step 2: Run every test in this phase**

```bash
flutter test test/core/employees/ test/core/widgets/status_metadata_test.dart
```

Expected: all PASS.

- [ ] **Step 3: No commit** — verification only, nothing changes.

---

## Self-Review

- **Spec coverage**: employee list (search, color swatch, status badge, FAB) — Task 9; create/edit (name, color, salary, notes, `joined` event on create) — Task 10; detail/timeline (status chip, merged timeline, Add event dialog with inline new-type creation) — Task 11; event-types manager (icon/color edits, new structural types, superadmin-gated) — Task 12; four-states rule — `loading`/`error`/`data`(empty-checked) branches present on every `.when(...)` in Tasks 9–12 (offline handling is Phase 1's `OfflineScreen`, wired at the router/shell level once Phase 7 assembles navigation — noted, not re-built here to avoid duplicating Phase 1's mechanism).
- **Placeholder scan**: no `TBD`/`TODO`/`FIXME` found; the one deliberately-omitted route (`/employees/:id/edit`) is explained inline in Task 13, not left as a silent gap.
- **Type consistency**: `Employee`/`EmployeeEvent`/`EventType`/`TimelineEntry` field names/types used identically across models (Tasks 1–4), repositories (Task 6), fakes (Task 7), providers (Task 8), and every page/test (Tasks 9–12) — verified by re-reading each usage while writing this plan.

**Flagged for the parent/Chirag, out of this plan's scope**: Phase 1's `event_types_insert` RLS policy (`core.is_admin_or_above()`) doesn't distinguish inserting a purely descriptive row from inserting a structural (`status_effect` set) one — as written, a plain admin could technically insert a structural row via a direct API call, even though the design intends that to be superadmin-only. This phase's app-level gating (event-types manager route restricted to `session.isSuperadmin`) doesn't close that gap for a non-UI caller. Real fix belongs in Phase 1's migration (e.g. a `check` constraint or a split policy requiring `core.is_superadmin()` specifically when `status_effect is not null`) — not fixed here since it's Phase 1's file.
