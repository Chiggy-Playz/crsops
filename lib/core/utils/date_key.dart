/// Date-only key (`yyyy-MM-dd`) for a [DateTime], used for PostgREST date
/// columns, provider keys, and calendar grouping. One definition for the
/// `toIso8601String().split('T').first` expression previously copy-pasted
/// across repositories and pages — the truncation uses the DateTime's own
/// (local) zone in every case, so centralizing changes no behavior.
String dateOnly(DateTime date) => date.toIso8601String().split('T').first;
