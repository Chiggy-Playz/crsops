import 'package:crs_ops/modules/attendance/pages/widgets/month_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts a [MonthCalendar] the way the app does (parent owns the month) and
/// records what it reports.
class _Harness {
  DateTime month;
  final taps = <DateTime>[];
  _Harness(this.month);
}

Future<_Harness> _pump(
  WidgetTester tester, {
  DateTime? month,
  DateTime? firstDate,
  DateTime? lastDate,
  double width = 800,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness(month ?? DateTime(2026, 10));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => MonthCalendar(
            month: h.month,
            firstDate: firstDate,
            lastDate: lastDate,
            onMonthChanged: (m) => setState(() => h.month = m),
            onDateTap: h.taps.add,
            dayBuilder: (
              context,
              day, {
              required isToday,
              required isSelected,
            }) => Center(child: Text('${day.day}')),
          ),
        ),
      ),
    ),
  );
  return h;
}

/// Number of day cells currently drawing the keyboard focus ring.
int _focusRings(WidgetTester tester) => tester
    .widgetList<Material>(find.byType(Material))
    .where((m) => m.shape is CircleBorder)
    .where((m) => (m.shape! as CircleBorder).side != BorderSide.none)
    .length;

void main() {
  group('MonthCalendar', () {
    testWidgets('lays out the month with Sunday-first weeks', (tester) async {
      await _pump(tester); // October 2026 starts on a Thursday

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      final thu = tester.getCenter(find.text('Thu')).dx;
      expect(tester.getCenter(find.text('1')).dx, closeTo(thu, 1));
    });

    testWidgets('arrows page by month', (tester) async {
      final h = await _pump(tester);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(h.month, DateTime(2026, 11));
      expect(find.text('November 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(h.month, DateTime(2026, 9));
    });

    testWidgets('the title opens a month picker with year arrows', (
      tester,
    ) async {
      final h = await _pump(tester);

      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);

      await tester.tap(find.text('Mar'));
      await tester.pumpAndSettle();
      expect(h.month, DateTime(2026, 3));

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Feb'));
      await tester.pumpAndSettle();
      expect(h.month, DateTime(2025, 2));
    });

    testWidgets('respects firstDate / lastDate', (tester) async {
      final h = await _pump(
        tester,
        month: DateTime(2025, 3),
        firstDate: DateTime(2025, 3, 10),
        lastDate: DateTime(2025, 4, 20),
      );

      // Days before the range can't be tapped.
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(h.taps, isEmpty);
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(h.taps, [DateTime(2025, 3, 12)]);

      // No paging before the first month; months outside are disabled.
      final prev = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prev.onPressed, isNull);
      await tester.tap(find.text('March 2025'));
      await tester.pumpAndSettle();
      final feb = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Feb'),
      );
      final may = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'May'),
      );
      expect(feb.onPressed, isNull);
      expect(may.onPressed, isNull);
    });

    testWidgets('keyboard moves across months and opens the day', (
      tester,
    ) async {
      final h = await _pump(tester, month: DateTime(2024, 2));

      await tester.tap(find.text('28'));
      await tester.pumpAndSettle();
      expect(h.taps.last, DateTime(2024, 2, 28));

      // 2024 is a leap year: 28 → 29 → 1 March.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(h.month, DateTime(2024, 3));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(h.taps.last, DateTime(2024, 3, 1));

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(h.month, DateTime(2024, 4));
    });

    testWidgets('shows the focus ring only while using the keyboard', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();
      expect(_focusRings(tester), 0); // a tap (phone) leaves no ring

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_focusRings(tester), 1);

      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      expect(_focusRings(tester), 0);
    });

    testWidgets('Today appears away from the current month and jumps back', (
      tester,
    ) async {
      final now = DateTime.now();
      final h = await _pump(tester, month: DateTime(now.year, now.month));
      expect(find.byTooltip('Today'), findsNothing);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Today'), findsOneWidget);

      await tester.tap(find.byTooltip('Today'));
      await tester.pumpAndSettle();
      expect(h.month, DateTime(now.year, now.month));
    });

    testWidgets('keeps the arrows in place whether or not Today shows', (
      tester,
    ) async {
      final now = DateTime.now();
      await _pump(tester, month: DateTime(now.year, now.month));
      final before = tester.getRect(find.byTooltip('Next month'));

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byTooltip('Next month')), before);
    });

    testWidgets('shortens a long month name on a narrow phone', (tester) async {
      await _pump(tester, month: DateTime(2026, 12), width: 360);

      expect(find.text('Dec 2026'), findsOneWidget);
      expect(find.text('December 2026'), findsNothing);
    });
  });
}
