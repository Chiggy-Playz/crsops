/// Ids of the built-in statuses seeded into `attendance.status_types`. The
/// app refers to these by id, so renaming one in the database means
/// changing it here, in one place.
abstract final class StatusIds {
  static const present = 'present';
  static const absent = 'absent';
  static const leave = 'leave';
  static const holiday = 'holiday';
  static const weekOff = 'week_off';

  /// The order statuses are offered in: the everyday ones first (what gets
  /// tapped most). Custom types come after these.
  static const builtInOrder = [present, absent, leave, holiday, weekOff];

  /// Not a status type: the report's bucket for working days nobody marked.
  static const unmarked = 'unmarked';
}
