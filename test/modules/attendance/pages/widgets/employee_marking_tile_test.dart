import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/widgets/employee_marking_tile.dart';
import 'package:crs_ops/modules/attendance/pages/widgets/status_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmployeeMarkingTile', () {
    final employee = Employee(
      id: '1',
      name: 'Ramesh',
      color: 0xFF4CAF50,
      createdAt: DateTime(2024),
    );
    const statusTypes = [
      StatusType(
        id: 'present',
        label: 'Present',
        iconName: 'check',
        colorHex: '#4CAF50',
      ),
    ];

    testWidgets('renders an unmarked tile and opens the sheet on tap', (
      tester,
    ) async {
      StatusPick? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmployeeMarkingTile(
              employee: employee,
              status: null,
              statusTypes: statusTypes,
              busy: false,
              onMarkStatus: (pick) => picked = pick,
              onUnmark: () => picked = null,
            ),
          ),
        ),
      );

      expect(find.text('Ramesh'), findsOneWidget);
      expect(find.text('Unmarked'), findsOneWidget);

      await tester.tap(find.text('Ramesh'));
      await tester.pumpAndSettle();

      expect(find.text('Mark Ramesh'), findsOneWidget);

      await tester.tap(find.text('Present'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.firstHalfStatus, 'present');
      expect(picked!.secondHalfStatus, 'present');
    });
  });
}
