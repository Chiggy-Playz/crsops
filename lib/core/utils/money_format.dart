import 'package:intl/intl.dart';

final _wholeRupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _withPaise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

bool _hasPaise(num amount) => amount != amount.truncate();

/// "₹25,000" for whole rupees, "₹1,500.50" when there are paise, so paise
/// are never silently rounded away.
String formatRupees(num amount) {
  if (_hasPaise(amount)) return _withPaise.format(amount);
  return _wholeRupees.format(amount);
}

/// The amount as typed into an edit field: "1500" or "1500.50".
String amountFieldText(num amount) {
  if (_hasPaise(amount)) return amount.toStringAsFixed(2);
  return amount.toStringAsFixed(0);
}
