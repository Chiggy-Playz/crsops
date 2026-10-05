import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Builds a day's content (number, dots, markers). The calendar itself owns
/// interaction: ripple, hover, keyboard focus, taps.
typedef MonthCalendarDayBuilder = Widget Function(
  BuildContext context,
  DateTime day, {
  required bool isToday,
  required bool isSelected,
});

/// An M3-style month grid (replaces table_calendar, which had no hover/press
/// feedback, no keyboard support, no month/year jump, and hardcoded
/// light-mode colours).
///
/// Controlled: the parent owns [month] and updates it from [onMonthChanged].
///
/// - Header: month year ▾ ‹ › — the title opens a month grid (‹ year ›
///   changes year); a Today button jumps back when looking elsewhere.
/// - Keyboard (when the grid has focus): arrows move a day / a week (into the
///   next or previous month), Page Up/Down change month, Enter or Space opens
///   the focused day.
/// - Days outside [firstDate]–[lastDate] are disabled; other months' days are
///   left blank so a month reads as one block.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.onMonthChanged,
    required this.onDateTap,
    required this.dayBuilder,
    this.selectedDate,
    this.firstDate,
    this.lastDate,
    this.semanticLabelFor,
  });

  /// Any day in the month to show.
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateTap;
  final MonthCalendarDayBuilder dayBuilder;
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Extra screen-reader text for a day (e.g. "3 present, 1 absent"),
  /// appended to its full date.
  final String? Function(DateTime day)? semanticLabelFor;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

enum _Mode { days, months }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _MonthCalendarState extends State<MonthCalendar> {
  final _gridFocus = FocusNode(debugLabel: 'MonthCalendar grid');
  _Mode _mode = _Mode.days;

  /// The year shown in the month picker (its ‹ year › arrows change it).
  int _pickerYear = DateTime.now().year;

  /// The keyboard cursor. Shown only while the grid has focus.
  late DateTime _focusedDay = _initialFocus();

  DateTime get _first => _dateOnly(widget.firstDate ?? DateTime(2000));
  DateTime get _last => _dateOnly(widget.lastDate ?? DateTime(2100, 12, 31));

  DateTime _initialFocus() {
    final selected = widget.selectedDate;
    if (selected != null && _monthOf(selected) == _monthOf(widget.month)) {
      return _dateOnly(selected);
    }
    final today = _dateOnly(DateTime.now());
    if (_monthOf(today) == _monthOf(widget.month)) return today;
    return DateTime(widget.month.year, widget.month.month);
  }

  @override
  void initState() {
    super.initState();
    _gridFocus.addListener(_rebuild);
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  @override
  void didUpdateWidget(MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_monthOf(oldWidget.month) != _monthOf(widget.month) &&
        _monthOf(_focusedDay) != _monthOf(widget.month)) {
      _focusedDay = _initialFocus();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    _gridFocus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onHighlightModeChanged(FocusHighlightMode _) => setState(() {});

  bool _isEnabled(DateTime day) => !day.isBefore(_first) && !day.isAfter(_last);

  bool _canShowMonth(DateTime month) =>
      !_monthOf(month).isBefore(_monthOf(_first)) &&
      !_monthOf(month).isAfter(_monthOf(_last));

  void _showMonth(DateTime month) {
    if (_canShowMonth(month)) widget.onMonthChanged(_monthOf(month));
  }

  void _moveFocus(int days) {
    final next = _focusedDay.add(Duration(days: days));
    final target = DateTime(next.year, next.month, next.day); // DST-safe
    if (!_isEnabled(target)) return;
    setState(() => _focusedDay = target);
    if (_monthOf(target) != _monthOf(widget.month)) _showMonth(target);
  }

  void _moveMonth(int months) {
    final target = DateTime(widget.month.year, widget.month.month + months);
    if (!_canShowMonth(target)) return;
    // Keep the day-of-month where possible (31 Jan → 28/29 Feb).
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final day = _focusedDay.day.clamp(1, lastDay);
    setState(() => _focusedDay = DateTime(target.year, target.month, day));
    _showMonth(target);
  }

  void _tap(DateTime day) {
    setState(() => _focusedDay = day);
    widget.onDateTap(day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        switch (_mode) {
          _Mode.days => _daysView(context),
          _Mode.months => _monthsView(context),
        },
      ],
    );
  }

  Widget _header(BuildContext context) {
    final title = DateFormat.yMMMM().format(widget.month);
    final now = DateTime.now();
    final showingToday =
        _monthOf(widget.month) == _monthOf(now) && _mode == _Mode.days;
    final prev = DateTime(widget.month.year, widget.month.month - 1);
    final next = DateTime(widget.month.year, widget.month.month + 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          // M3 date-picker style: the title toggles the month picker.
          // Takes all the spare width (title left-aligned, ellipsised if
          // tight), so the arrows stay pinned to the right edge whether or not
          // the Today button is showing.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    if (_mode == _Mode.days) {
                      _pickerYear = widget.month.year;
                      _mode = _Mode.months;
                    } else {
                      _mode = _Mode.days;
                    }
                  }),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    _mode == _Mode.days
                        ? Icons.arrow_drop_down
                        : Icons.arrow_drop_up,
                  ),
                  label: Text(
                    _fits(context, title, constraints.maxWidth)
                        ? title
                        : DateFormat.yMMM().format(widget.month),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          if (!showingToday && _canShowMonth(now))
            // An icon (like Google Calendar's) so the header fits on phones.
            IconButton(
              tooltip: 'Today',
              icon: const Icon(Icons.today),
              onPressed: () {
                setState(() {
                  _mode = _Mode.days;
                  _focusedDay = _dateOnly(now);
                });
                _showMonth(now);
              },
            ),
          if (_mode == _Mode.days) ...[
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              onPressed: _canShowMonth(prev) ? () => _moveMonth(-1) : null,
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              onPressed: _canShowMonth(next) ? () => _moveMonth(1) : null,
            ),
          ],
        ],
      ),
    );
  }

  /// Whether [text] fits in a TextButton.icon [maxWidth] wide (label style,
  /// user's text scale, plus the button's padding and dropdown icon). When it
  /// doesn't — "December 2026" on a narrow phone — the header shows the short
  /// month ("Dec 2026") rather than cutting it off.
  bool _fits(BuildContext context, String text, double maxWidth) {
    const buttonChrome = 12 + 8 + 18 + 16; // padding, gap, icon, slack
    final painter = TextPainter(
      text: TextSpan(text: text, style: Theme.of(context).textTheme.labelLarge),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final fits = painter.width + buttonChrome <= maxWidth;
    painter.dispose();
    return fits;
  }

  Widget _daysView(BuildContext context) {
    final theme = Theme.of(context);
    final month = _monthOf(widget.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Sunday-first weeks: DateTime.weekday is 1 (Mon) … 7 (Sun).
    final leadingBlanks = month.weekday % 7;
    final cellCount = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final today = _dateOnly(DateTime.now());
    final selected = widget.selectedDate == null
        ? null
        : _dateOnly(widget.selectedDate!);
    final weekdayFormat = DateFormat.E();
    // 2023-01-01 was a Sunday: a fixed week to read the weekday names from.
    final weekdayNames = [
      for (var i = 0; i < 7; i++)
        weekdayFormat.format(DateTime(2023, 1, 1 + i)),
    ];

    return FocusableActionDetector(
      focusNode: _gridFocus,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-7),
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(7),
        SingleActivator(LogicalKeyboardKey.pageUp): _MonthIntent(-1),
        SingleActivator(LogicalKeyboardKey.pageDown): _MonthIntent(1),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (i) => _moveFocus(i.days),
        ),
        _MonthIntent: CallbackAction<_MonthIntent>(
          onInvoke: (i) => _moveMonth(i.months),
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => _tap(_focusedDay),
        ),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          // Roughly square cells, within sensible bounds on phones/desktops.
          final cellHeight = cellWidth.clamp(44.0, 64.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final name in weekdayNames)
                    SizedBox(
                      width: cellWidth,
                      height: 32,
                      child: Center(
                        child: ExcludeSemantics(
                          child: Text(
                            name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (var row = 0; row < cellCount ~/ 7; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      SizedBox(
                        width: cellWidth,
                        height: cellHeight,
                        child: _cell(
                          context,
                          dayNumber: row * 7 + col - leadingBlanks + 1,
                          daysInMonth: daysInMonth,
                          month: month,
                          today: today,
                          selected: selected,
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(
    BuildContext context, {
    required int dayNumber,
    required int daysInMonth,
    required DateTime month,
    required DateTime today,
    required DateTime? selected,
  }) {
    if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox();

    final day = DateTime(month.year, month.month, dayNumber);
    final enabled = _isEnabled(day);
    final isSelected = selected != null && _sameDay(day, selected);
    // Like Flutter's own buttons: the focus ring only while using a keyboard.
    // After a tap the grid keeps focus (so arrows work next), but on touch or
    // mouse the ring would just read as a second "today".
    final usingKeyboard =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final hasKeyboardFocus =
        usingKeyboard && _gridFocus.hasFocus && _sameDay(day, _focusedDay);
    final scheme = Theme.of(context).colorScheme;

    final extra = widget.semanticLabelFor?.call(day);
    final label = [
      DateFormat.yMMMMEEEEd().format(day),
      if (_sameDay(day, today)) 'today',
      ?extra,
    ].join(', ');

    Widget content = widget.dayBuilder(
      context,
      day,
      isToday: _sameDay(day, today),
      isSelected: isSelected,
    );
    if (!enabled) content = Opacity(opacity: 0.38, child: content);

    return Semantics(
      label: label,
      button: enabled,
      selected: isSelected,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          type: MaterialType.transparency,
          shape: CircleBorder(
            side: hasKeyboardFocus
                ? BorderSide(color: scheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            canRequestFocus: false, // the grid owns keyboard focus
            onTap: enabled
                ? () {
                    _gridFocus.requestFocus();
                    _tap(day);
                  }
                : null,
            child: content,
          ),
        ),
      ),
    );
  }

  /// The 12 months of [_pickerYear], with ‹ year › to change year — most
  /// jumps are a few months back in the same year, so a month is one click.
  Widget _monthsView(BuildContext context) {
    final year = _pickerYear;
    final monthFormat = DateFormat.MMM();
    final canGoBack = _canShowMonth(DateTime(year - 1, 12));
    final canGoForward = _canShowMonth(DateTime(year + 1, 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous year',
              icon: const Icon(Icons.chevron_left),
              onPressed: canGoBack ? () => setState(() => _pickerYear--) : null,
            ),
            SizedBox(
              width: 72,
              child: Text(
                '$year',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Next year',
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoForward
                  ? () => setState(() => _pickerYear++)
                  : null,
            ),
          ],
        ),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 52,
          ),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          children: [
            for (var m = 1; m <= 12; m++)
              _choiceChip(
                context,
                label: monthFormat.format(DateTime(year, m)),
                selected: year == widget.month.year && m == widget.month.month,
                onTap: _canShowMonth(DateTime(year, m))
                    ? () {
                        setState(() {
                          _mode = _Mode.days;
                          _focusedDay = DateTime(year, m);
                        });
                        _showMonth(DateTime(year, m));
                      }
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _choiceChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: selected
          ? FilledButton(onPressed: onTap, child: Text(label))
          : TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
              child: Text(label),
            ),
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.days);
  final int days;
}

class _MonthIntent extends Intent {
  const _MonthIntent(this.months);
  final int months;
}
