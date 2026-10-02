// Reusable, re-runnable tool: reads a Firestore export of the old
// crs_attendance app and generates one reviewable, transaction-wrapped SQL
// file that imports it into the live core/attendance schema. Never executes
// against the database itself -- the generated file is reviewed by hand,
// then pasted into Studio's SQL editor or run via `supabase db execute`.
//
// Usage: dart run tool/generate_legacy_import.dart <path-to-backup.json> [output.sql]
//
// See docs/plan/2026-10-03-chore-import-legacy-attendance-data-plan.md for
// the full design and the real-data findings that shaped it.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Old Firestore `attendance.date` fields are local IST midnight stored as
/// UTC (confirmed: every record in the real export ends in exactly
/// T18:30:00.000Z). Adding 5:30 recovers the correct calendar date.
DateTime correctAttendanceDate(String isoUtc) {
  final utc = DateTime.parse(isoUtc).toUtc();
  final corrected = utc.add(const Duration(hours: 5, minutes: 30));
  return DateTime.utc(corrected.year, corrected.month, corrected.day);
}

/// Cross-checks the corrected date against the Firestore doc key's own
/// `D-M-YYYY` prefix (the key is `D-M-YYYY-employeeId`). Throws if they
/// disagree -- this caught the date-correction bug for real once already,
/// so it stays as a standing assertion for future exports too.
void assertKeyDateMatches(String key, String employeeId, DateTime corrected) {
  final datePart = key.substring(0, key.length - employeeId.length - 1);
  final parts = datePart.split('-');
  if (parts.length != 3) {
    throw FormatException('Unrecognized attendance key shape: $key');
  }
  final keyDate = DateTime.utc(
    int.parse(parts[2]),
    int.parse(parts[1]),
    int.parse(parts[0]),
  );
  if (keyDate != corrected) {
    throw FormatException(
      'Date mismatch for $key: key says $keyDate, '
      'date field corrects to $corrected',
    );
  }
}

/// User decision: 0 means "never recorded," not a real ₹0 salary.
num? mapSalary(num salary) => salary == 0 ? null : salary;

/// Trims and SQL-escapes a name for a single-quoted literal.
String sqlEscapeName(String raw) => raw.trim().replaceAll("'", "''");

/// Old statuses map 1:1 onto both halves of a day, except `halfDay`: there's
/// no time data anywhere in the export to say which half was worked, so it
/// defaults to present/absent and is flagged for manual review.
(String firstHalf, String secondHalf, bool flagged) statusesFor(
  String oldStatus,
) {
  switch (oldStatus) {
    case 'present':
      return ('present', 'present', false);
    case 'absent':
      return ('absent', 'absent', false);
    case 'holiday':
      return ('holiday', 'holiday', false);
    case 'halfDay':
      return ('present', 'absent', true);
    default:
      throw FormatException('Unrecognized attendance status: $oldStatus');
  }
}

/// `joined` is always the earliest attendance date (createdAt is confirmed
/// unreliable); `left` only exists for disabled employees, dated at their
/// latest attendance date.
({DateTime joined, DateTime? left}) deriveEvents({
  required List<DateTime> attendanceDates,
  required bool disabled,
}) {
  if (attendanceDates.isEmpty) {
    throw StateError('No attendance records -- cannot derive a join date.');
  }
  final sorted = [...attendanceDates]..sort();
  return (joined: sorted.first, left: disabled ? sorted.last : null);
}

/// Hand-rolled v4 UUID -- no new pubspec dependency for a one-off script.
String generateUuidV4(Random rng) {
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class _HalfDayFlag {
  _HalfDayFlag(this.name, this.date);
  final String name;
  final DateTime date;
}

/// One VALUES row plus an optional trailing `-- comment`. Kept separate from
/// the row's own comma/semicolon so a comment can never swallow either --
/// SQL line comments run to end of line, so `value, -- comment` followed by
/// `;` on the next line is fine, but `value, -- comment;` is not: the `;`
/// would be part of the comment and the statement would never terminate.
class _Row {
  _Row(this.value, [this.comment]);
  final String value;
  final String? comment;
}

/// Renders rows with the comma/semicolon placed before any trailing
/// comment, never after.
String _valuesBlock(List<_Row> rows) {
  final buffer = StringBuffer();
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final terminator = i == rows.length - 1 ? ';' : ',';
    final suffix = row.comment == null ? '' : ' ${row.comment}';
    buffer.writeln('  ${row.value}$terminator$suffix');
  }
  return buffer.toString();
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/generate_legacy_import.dart '
      '<path-to-backup.json> [output.sql]',
    );
    exit(64);
  }

  final input = File(args[0]);
  if (!input.existsSync()) {
    stderr.writeln('No such file: ${args[0]}');
    exit(66);
  }

  final data = jsonDecode(input.readAsStringSync()) as Map<String, dynamic>;
  final employees = (data['employees'] as Map<String, dynamic>);
  final attendance = (data['attendance'] as Map<String, dynamic>);

  // employeeId -> sorted (date, oldStatus) pairs.
  final attendanceByEmployee = <String, List<(DateTime, String)>>{};
  for (final entry in attendance.entries) {
    final record = entry.value as Map<String, dynamic>;
    final employeeId = record['employeeId'] as String;
    if (!employees.containsKey(employeeId)) {
      throw StateError(
        'Attendance record ${entry.key} references unknown employee '
        '$employeeId',
      );
    }
    final corrected = correctAttendanceDate(record['date'] as String);
    assertKeyDateMatches(entry.key, employeeId, corrected);
    attendanceByEmployee.putIfAbsent(employeeId, () => []).add((
      corrected,
      record['status'] as String,
    ));
  }

  final rng = Random.secure();
  final employeeRows = <_Row>[];
  final eventRows = <_Row>[];
  final attendanceRows = <_Row>[];
  final halfDayFlags = <_HalfDayFlag>[];
  var leftEventCount = 0;

  for (final entry in employees.entries) {
    final oldId = entry.key;
    final employee = entry.value as Map<String, dynamic>;
    final name = sqlEscapeName(employee['name'] as String);
    final disabled = employee['disabled'] as bool;
    final color = employee['color'] as int;
    final salary = mapSalary(employee['salary'] as num);

    final dates = attendanceByEmployee[oldId];
    if (dates == null || dates.isEmpty) {
      throw StateError(
        'Employee $oldId ($name) has zero attendance records -- cannot '
        'derive a join date. Refusing to generate a partial import.',
      );
    }

    final newId = generateUuidV4(rng);

    employeeRows.add(
      _Row("('$newId', '$name', $color, ${salary ?? 'null'})", '-- was $oldId'),
    );

    final events = deriveEvents(
      attendanceDates: dates.map((d) => d.$1).toList(),
      disabled: disabled,
    );
    eventRows.add(
      _Row(
        "('$newId', 'joined', '${formatDate(events.joined)}', "
        "'Imported from legacy app (first attendance record)', "
        "'${formatDate(events.joined)}T00:00:00Z')",
      ),
    );
    if (events.left != null) {
      leftEventCount++;
      eventRows.add(
        _Row(
          "('$newId', 'left', '${formatDate(events.left!)}', "
          "'Imported from legacy app (last attendance record; "
          "disabled=true)', '${formatDate(events.left!)}T00:00:01Z')",
        ),
      );
    }

    for (final (date, oldStatus) in dates) {
      final (firstHalf, secondHalf, flagged) = statusesFor(oldStatus);
      attendanceRows.add(
        _Row(
          "('$newId', '${formatDate(date)}', '$firstHalf', '$secondHalf')",
          flagged
              ? '-- halfDay, no time data to disambiguate, verify manually'
              : null,
        ),
      );
      if (flagged) halfDayFlags.add(_HalfDayFlag(name, date));
    }
  }

  final employeeCount = employees.length;
  final eventCount = employeeCount + leftEventCount;
  final attendanceCount = attendance.length;

  final finalSql =
      '''
begin;

-- Refuses to run against a non-empty table, so a second accidental run (or
-- a stale test-run's leftovers) can never silently double-insert.
-- Deliberate wipe is supabase/legacy_imports/undo.sql, run first and on
-- purpose when re-importing fresh data.
do \$\$
begin
  if exists (select 1 from core.employees) then
    raise exception 'core.employees is not empty — run supabase/legacy_imports/undo.sql first if you intend to re-import.';
  end if;
end \$\$;

insert into core.employees (id, name, color, salary) values
${_valuesBlock(employeeRows)}
insert into core.employee_events (employee_id, event_type, event_date, note, created_at) values
${_valuesBlock(eventRows)}
insert into attendance.attendance_days (employee_id, date, first_half_status, second_half_status) values
${_valuesBlock(attendanceRows)}
-- Self-describing verification, computed from this run's own input --
-- never hardcoded, so it always matches whatever export was fed in. Aborts
-- the whole transaction (rolling back everything above) on any mismatch.
do \$\$
declare emp_count int; evt_count int; att_count int;
begin
  select count(*) into emp_count from core.employees;
  select count(*) into evt_count from core.employee_events where event_type in ('joined','left');
  select count(*) into att_count from attendance.attendance_days;
  if emp_count <> $employeeCount or evt_count <> $eventCount or att_count <> $attendanceCount then
    raise exception 'count mismatch: employees=%, events=%, attendance_days=% (expected $employeeCount/$eventCount/$attendanceCount)',
      emp_count, evt_count, att_count;
  end if;
end \$\$;

commit;
''';

  final outputPath = args.length > 1
      ? args[1]
      : 'supabase/legacy_imports/'
            '${DateTime.now().toIso8601String().replaceAll(RegExp('[:.]'), '-')}.sql';
  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(finalSql);

  stdout.writeln('Wrote $outputPath');
  stdout.writeln(
    '$employeeCount employees, $eventCount events '
    '($leftEventCount left), $attendanceCount attendance_days.',
  );
  if (halfDayFlags.isNotEmpty) {
    stdout.writeln(
      '\n${halfDayFlags.length} halfDay rows defaulted to present/absent '
      '-- verify manually:',
    );
    for (final flag in halfDayFlags) {
      stdout.writeln('  ${flag.name} — ${formatDate(flag.date)}');
    }
  }
}
