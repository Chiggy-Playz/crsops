// Indian financial years run April to March and are stored by their starting
// year: April 2026 to March 2027 is 2026, shown as "2026-27". Same rule as the
// database's challans.financial_year_of.

/// The financial year [date] falls in.
int financialYearOf(DateTime date) =>
    date.month < 4 ? date.year - 1 : date.year;

/// "2026-27".
String financialYearLabel(int year) {
  final nextYear = ((year + 1) % 100).toString().padLeft(2, '0');
  return '$year-$nextYear';
}

/// How a challan is referred to everywhere: "12 / 2026-27".
String challanNumberLabel(int number, int financialYear) =>
    '$number / ${financialYearLabel(financialYear)}';

/// "26-27", as the old exports wrote it.
String shortFinancialYearLabel(int year) {
  String twoDigits(int y) => (y % 100).toString().padLeft(2, '0');
  return '${twoDigits(year)}-${twoDigits(year + 1)}';
}
