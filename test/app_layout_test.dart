// Whole-app layout tests: each section at a wide window (two panes) and a
// phone-sized one (single pages), driven through the real router with fake
// repositories.
import 'package:crs_ops/app_router.dart';
import 'package:crs_ops/app_sections.dart';
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/models/profile.dart';
import 'package:crs_ops/core/auth/providers/admin_providers.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/data/shared_preferences_provider.dart';
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/core/sections/app_sections_provider.dart';
import 'package:crs_ops/core/theme/app_theme.dart';
import 'package:crs_ops/core/utils/date_key.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/attendance_day_page.dart';
import 'package:crs_ops/modules/attendance/pages/calendar_page.dart';
import 'package:crs_ops/modules/attendance/pages/widgets/month_calendar.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/fakes/fake_admin_repository.dart';
import 'core/employees/fakes/fake_employee_event_repository.dart';
import 'core/employees/fakes/fake_employee_ledger_entry_repository.dart';
import 'core/employees/fakes/fake_employee_repository.dart';
import 'core/employees/fakes/fake_event_type_repository.dart';
import 'modules/attendance/fakes/fake_attendance_repository.dart';
import 'modules/attendance/fakes/fake_shift_defaults_repository.dart';
import 'modules/attendance/fakes/fake_status_type_repository.dart';

final _today = DateTime.now();
final _todayDate = DateTime(_today.year, _today.month, _today.day);

Future<GoRouter> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      appSectionsProvider.overrideWithValue(allSections),
      sharedPreferencesProvider.overrideWithValue(prefs),
      sessionProvider.overrideWithValue(
        const AsyncData(
          AppSession(
            userId: 'u',
            email: 'boss@x.com',
            role: AppRole.superadmin,
            moduleAccess: {},
          ),
        ),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(
          seed: [
            Employee(
              id: 'e1',
              name: 'Asha',
              color: 0,
              createdAt: DateTime(2024),
            ),
            Employee(
              id: 'e2',
              name: 'Bharat',
              color: 0,
              createdAt: DateTime(2024),
            ),
          ],
          statusById: {'e1': 'active', 'e2': 'active'},
        ),
      ),
      employeeEventRepositoryProvider.overrideWithValue(
        FakeEmployeeEventRepository(),
      ),
      eventTypeRepositoryProvider.overrideWithValue(FakeEventTypeRepository()),
      employeeLedgerEntryRepositoryProvider.overrideWithValue(
        FakeEmployeeLedgerEntryRepository(),
      ),
      attendanceRepositoryProvider.overrideWithValue(
        FakeAttendanceRepository(
          rangeStatusSeed: [
            EffectiveStatusRow(
              employeeId: 'e1',
              date: _todayDate,
              isExplicit: false,
              isWeekOff: false,
            ),
          ],
        ),
      ),
      statusTypeRepositoryProvider.overrideWithValue(
        FakeStatusTypeRepository(
          seed: const [
            StatusType(
              id: 'present',
              label: 'Present',
              iconName: 'check',
              colorHex: '#4CAF50',
            ),
          ],
        ),
      ),
      shiftDefaultsRepositoryProvider.overrideWithValue(
        FakeShiftDefaultsRepository(),
      ),
      adminRepositoryProvider.overrideWithValue(
        FakeAdminRepository(
          profiles: [
            Profile(id: 'u2', email: 'staff@x.com', createdAt: DateTime(2024)),
          ],
          roles: {'u2': 'employee'},
          modules: [(id: 'attendance', name: 'Attendance')],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildAppTheme(brightness: Brightness.dark),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _loc(GoRouter r) =>
    r.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets(
    'attendance (wide): opens on today next to the calendar; dates swap the right pane',
    (tester) async {
      final r = await _pumpApp(tester, const Size(1400, 900));
      expect(_loc(r), '/attendance/${dateOnly(_today)}');
      expect(find.byType(CalendarPage), findsOneWidget);
      expect(find.byType(AttendanceDayPage), findsOneWidget);
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Mark all present'), findsOneWidget); // list row
      expect(find.byType(FloatingActionButton), findsNothing);
      // pick another date in the calendar
      final other = _today.day == 15 ? '16' : '15';
      await tester.tap(
        find
            .descendant(
              of: find.byType(CalendarPage),
              matching: find.text(other),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(_loc(r), startsWith('/attendance/${_today.year}-'));
      expect(_loc(r), endsWith('-$other'));
      expect(find.byType(CalendarPage), findsOneWidget);
      expect(find.byType(AttendanceDayPage), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    },
  );

  testWidgets(
    'attendance (phone): calendar page, day page pushed with a back arrow',
    (tester) async {
      final r = await _pumpApp(tester, const Size(400, 850));
      expect(_loc(r), '/attendance/calendar');
      expect(find.byType(AttendanceDayPage), findsNothing);
      await tester.tap(find.text('${_today.day}').first);
      await tester.pumpAndSettle();
      expect(find.byType(AttendanceDayPage), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(_loc(r), '/attendance/calendar');
    },
  );

  testWidgets('status picker is a dialog on wide windows', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));
    await tester.tap(find.text('Asha'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets(
    'employees (wide): empty state, then list + detail with action rows',
    (tester) async {
      final r = await _pumpApp(tester, const Size(1400, 900));
      r.go('/employees');
      await tester.pumpAndSettle();
      expect(find.text('Select an employee'), findsOneWidget);
      expect(find.text('Asha'), findsOneWidget);
      await tester.tap(find.text('Asha'));
      await tester.pumpAndSettle();
      expect(_loc(r), '/employees/e1');
      expect(find.text('Select an employee'), findsNothing);
      expect(find.text('Bharat'), findsOneWidget); // list still there
      // wide: actions are list rows, no floating buttons
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('New employee'), findsOneWidget);
      expect(find.text('Add event or payment'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add-button')));
      await tester.pumpAndSettle();
      expect(find.text('Payment'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets('employees (phone): list page, detail pushed', (tester) async {
    final r = await _pumpApp(tester, const Size(400, 850));
    r.go('/employees');
    await tester.pumpAndSettle();
    expect(find.text('Select an employee'), findsNothing);
    await tester.tap(find.text('Asha'));
    await tester.pumpAndSettle();
    expect(_loc(r), '/employees/e1');
    expect(find.text('Bharat'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('settings (wide): empty state, then hub + page', (tester) async {
    final r = await _pumpApp(tester, const Size(1400, 900));
    r.go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Choose a setting'), findsOneWidget);
    await tester.tap(find.text('Roles'));
    await tester.pumpAndSettle();
    expect(_loc(r), '/settings/roles');
    expect(find.text('staff@x.com'), findsOneWidget);
    expect(find.text('Signup allow-list'), findsOneWidget); // hub still there
    await tester.tap(find.text('Status types'));
    await tester.pumpAndSettle();
    expect(_loc(r), '/settings/attendance/status-types');
  });

  testWidgets('settings (phone): hub page, page pushed', (tester) async {
    final r = await _pumpApp(tester, const Size(400, 850));
    r.go('/settings');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roles'));
    await tester.pumpAndSettle();
    expect(_loc(r), '/settings/roles');
    expect(find.text('Signup allow-list'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Signup allow-list'), findsOneWidget);
  });

  for (final w in [1400.0, 1000.0, 400.0]) {
    testWidgets('reports at ${w}px: range menu offers Previous month', (
      tester,
    ) async {
      final r = await _pumpApp(tester, Size(w, 900));
      r.go('/attendance/reports');
      await tester.pumpAndSettle();
      expect(find.text('Calendar view'), findsOneWidget);
      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();
      expect(find.text('Previous month'), findsOneWidget);
      await tester.tap(find.text('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('Previous month'), findsOneWidget); // chip label now
    });
  }

  for (final w in [1400.0, 400.0]) {
    testWidgets('reports employee picker at ${w}px', (tester) async {
      final r = await _pumpApp(tester, Size(w, 900));
      r.go('/attendance/reports');
      await tester.pumpAndSettle();
      await tester.tap(find.text('All employees'));
      await tester.pumpAndSettle();
      expect(find.text('Filter by employee'), findsOneWidget);
      expect(find.text('Showing everyone'), findsOneWidget);
      await tester.tap(find.text('Asha'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Asha'), findsWidgets); // chip label shows the name
      expect(find.text('Filter by employee'), findsNothing);
    });
  }

  // Regression: Reports is outside the attendance shell; pushing the shell's
  // day route from it stacked a second shell (duplicate page key → crash).
  // Days now open on top of Reports and close back to it, filters intact.
  for (final w in [1400.0, 400.0]) {
    testWidgets('a day opened from the Reports calendar closes back to it at '
        '${w}px', (tester) async {
      final r = await _pumpApp(tester, Size(w, 900));
      r.push('/attendance/reports');
      await tester.pumpAndSettle();
      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Previous month'));
      await tester.pumpAndSettle();

      final calendar = find.byType(MonthCalendar);
      await tester.tap(
        find.descendant(of: calendar, matching: find.text('3')).first,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_loc(r), startsWith('/attendance/reports/'));
      expect(find.byType(AttendanceDayPage), findsOneWidget);

      // ✕ in the wide dialog, back arrow on phones.
      if (w > 840) {
        await tester.tap(find.byType(CloseButton));
      } else {
        await tester.tap(find.byType(BackButton));
      }
      await tester.pumpAndSettle();

      expect(_loc(r), '/attendance/reports');
      expect(find.byType(AttendanceDayPage), findsNothing);
      expect(find.text('Previous month'), findsOneWidget); // filter kept
    });
  }

  // Regression: the two-pane decision used the window width and ignored the
  // navigation's own width, so at ~860px the drawer + calendar left the day
  // pane ~140px wide. Navigation and panes now share one width rule.
  for (final (width, nav, twoPanes) in [
    (860.0, NavigationRail, false), // rail + one page (the reported case)
    (1000.0, NavigationRail, true), // rail + two panes
    (1300.0, NavigationDrawer, true), // drawer + two panes
  ]) {
    testWidgets('at ${width}px: $nav, two panes: $twoPanes', (tester) async {
      await _pumpApp(tester, Size(width, 900));

      expect(find.byType(nav), findsOneWidget);
      if (twoPanes) {
        expect(find.byType(CalendarPage), findsOneWidget);
        expect(find.byType(AttendanceDayPage), findsOneWidget);
      } else {
        expect(find.byType(CalendarPage), findsOneWidget);
        expect(find.byType(AttendanceDayPage), findsNothing);
      }
    });
  }
}
