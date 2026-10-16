import 'dart:async';

import 'package:crs_ops/app_router.dart';
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/core/sections/app_sections_provider.dart';
import 'package:crs_ops/core/utils/date_time_format.dart';
import 'package:crs_ops/modules/attendance/attendance_section.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:crs_ops/core/router/back_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/employees/fakes/fake_employee_repository.dart';
import 'fakes/fake_attendance_repository.dart';
import 'fakes/fake_status_type_repository.dart';

void main() {
  testWidgets('back after closing the holiday dialog still stays in the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final today = DateTime.parse(dateOnly(DateTime.now()));
    final container = ProviderContainer(
      overrides: [
        appSectionsProvider.overrideWithValue([attendanceSection]),
        sessionProvider.overrideWithValue(
          const AsyncData(
            AppSession(
              userId: 'u',
              email: 'e',
              role: AppRole.superadmin,
              moduleAccess: {},
            ),
          ),
        ),
        employeeRepositoryProvider.overrideWithValue(
          FakeEmployeeRepository(
            seed: [
              Employee(
                id: '1',
                name: 'Ramesh',
                color: 0xFF4CAF50,
                createdAt: DateTime(2024, 1, 1),
              ),
            ],
          ),
        ),
        attendanceRepositoryProvider.overrideWithValue(
          FakeAttendanceRepository(
            rangeStatusSeed: [
              EffectiveStatusRow(
                employeeId: '1',
                date: today,
                isExplicit: false,
                isWeekOff: false,
              ),
            ],
          ),
        ),
        statusTypeRepositoryProvider.overrideWithValue(
          FakeStatusTypeRepository(seed: const []),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    // What the app last told Android about whether back stays inside it.
    bool? frameworkHandlesBack;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          frameworkHandlesBack = call.arguments as bool;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          onNavigationNotification: reportBackState(router.canPop),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Calendar → a day, as a phone does.
    unawaited(router.push('/attendance/${dateOnly(today)}'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mark-holiday-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark-holiday-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mark-holiday-confirm-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mark-holiday-confirm-dialog')), findsNothing);
    expect(router.canPop(), isTrue);
    expect(frameworkHandlesBack, isTrue);
  });
}
