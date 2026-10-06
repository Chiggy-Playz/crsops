/// GSTIN helpers for the address form. The database checks the same shape
/// (`core.clean_gstin`); checking here too lets the form say what's wrong
/// before saving.
library;

final _gstinPattern = RegExp(
  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
);

/// Upper-cased with spaces removed, or null when blank.
String? cleanGstin(String? input) {
  final cleaned = (input ?? '').replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (cleaned.isEmpty) return null;
  return cleaned;
}

/// A form-field validator: blank is fine (GSTIN is optional).
String? validateGstin(String? input) {
  final cleaned = cleanGstin(input);
  if (cleaned == null) return null;
  if (cleaned.length != 15) {
    return 'A GSTIN has 15 characters (this has ${cleaned.length})';
  }
  if (!_gstinPattern.hasMatch(cleaned)) {
    return "This doesn't look like a GSTIN";
  }
  return null;
}

/// The state a GSTIN is registered in: its first two digits. Null when the
/// input isn't a valid GSTIN.
String? gstinStateCode(String? input) {
  final cleaned = cleanGstin(input);
  if (cleaned == null || !_gstinPattern.hasMatch(cleaned)) return null;
  return cleaned.substring(0, 2);
}
