// Rupees in words the Indian way (lakh, crore), as the old app printed them:
// each word capitalised, no "and" — 1,50,025 is "One Lakh Fifty Thousand
// Twenty Five".

const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

/// 0–99 in words; empty for 0.
String _belowHundred(int number) {
  if (number < 20) return _ones[number];
  final ones = _ones[number % 10];
  final tens = _tens[number ~/ 10];
  if (ones.isEmpty) return tens;
  return '$tens $ones';
}

/// 0–999 in words; empty for 0.
String _belowThousand(int number) {
  final hundreds = number ~/ 100;
  final rest = _belowHundred(number % 100);
  final parts = [
    if (hundreds > 0) '${_ones[hundreds]} Hundred',
    if (rest.isNotEmpty) rest,
  ];
  return parts.join(' ');
}

/// [amount] in words; "Zero" for 0. Crores above 99 are themselves said in
/// words ("One Hundred Twenty Crore").
String amountInWords(int amount) {
  if (amount == 0) return 'Zero';

  final crores = amount ~/ 10000000;
  final lakhs = (amount ~/ 100000) % 100;
  final thousands = (amount ~/ 1000) % 100;
  final rest = amount % 1000;

  final parts = [
    if (crores > 0) '${amountInWords(crores)} Crore',
    if (lakhs > 0) '${_belowHundred(lakhs)} Lakh',
    if (thousands > 0) '${_belowHundred(thousands)} Thousand',
    if (rest > 0) _belowThousand(rest),
  ];
  return parts.join(' ');
}
