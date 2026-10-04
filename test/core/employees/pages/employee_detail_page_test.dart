import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:crs_ops/core/employees/models/timeline_entry.dart';
import 'package:crs_ops/core/employees/pages/employee_detail_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_employee_event_repository.dart';
import '../fakes/fake_employee_ledger_entry_repository.dart';
import '../fakes/fake_employee_repository.dart';
import '../fakes/fake_event_type_repository.dart';

void main() {
  testWidgets('shows the timeline merging events and ledger entries by date', (
    tester,
  ) async {
    final employeeRepo = FakeEmployeeRepository(
      seed: [
        Employee(
          id: '1',
          name: 'Ramesh',
          color: 0xFF4CAF50,
          createdAt: DateTime(2024, 1, 1),
        ),
      ],
      statusById: {'1': 'active'},
    );
    final eventRepo = FakeEmployeeEventRepository(
      seed: [
        TimelineEntry(
          id: 'e1',
          employeeId: '1',
          entryDate: DateTime(2024, 1, 10),
          kind: 'event',
          label: 'joined',
        ),
        TimelineEntry(
          id: 'l1',
          employeeId: '1',
          entryDate: DateTime(2024, 2, 1),
          kind: 'ledger',
          label: 'advance',
          amount: 5000,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(employeeRepo),
          employeeEventRepositoryProvider.overrideWithValue(eventRepo),
          eventTypeRepositoryProvider.overrideWithValue(
            FakeEventTypeRepository(),
          ),
        ],
        child: const MaterialApp(home: EmployeeDetailPage(employeeId: '1')),
      ),
    );
    await tester.pumpAndSettle();

    // Shown once, in the profile header (the app bar has no title).
    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('Joined'), findsOneWidget);
    expect(find.text('Advance'), findsOneWidget);
  });

  testWidgets(
    'Add event button opens a dialog that inserts a new descriptive type inline',
    (tester) async {
      final eventTypeRepo = FakeEventTypeRepository(
        seed: [const EventType(id: 'joined', statusEffect: 'active')],
      );
      final eventRepo = FakeEmployeeEventRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
            employeeEventRepositoryProvider.overrideWithValue(eventRepo),
            eventTypeRepositoryProvider.overrideWithValue(eventTypeRepo),
          ],
          child: const MaterialApp(home: EmployeeDetailPage(employeeId: '1')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-event-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add-event-dialog')), findsOneWidget);
    },
  );

  testWidgets(
    'Add payment button opens a dialog that records a new ledger entry',
    (tester) async {
      final ledgerRepo = FakeEmployeeLedgerEntryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
            employeeEventRepositoryProvider.overrideWithValue(
              FakeEmployeeEventRepository(),
            ),
            eventTypeRepositoryProvider.overrideWithValue(
              FakeEventTypeRepository(),
            ),
            employeeLedgerEntryRepositoryProvider.overrideWithValue(ledgerRepo),
          ],
          child: const MaterialApp(home: EmployeeDetailPage(employeeId: '1')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-payment-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add-payment-dialog')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('payment-amount-field')),
        '5000',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('payment-category-field')),
        'advance',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment-save-button')));
      await tester.pumpAndSettle();

      expect(ledgerRepo.addedEntries, hasLength(1));
      expect(ledgerRepo.addedEntries.first['amount'], 5000.0);
    },
  );
}
