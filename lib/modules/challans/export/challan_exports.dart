import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../../core/export/xlsx_writer.dart';
import '../financial_year.dart';
import '../models/challan.dart';

// The two spreadsheets the old app exported from search results: same
// columns, text, order and look (checked cell by cell against the old app's
// output for real challans).

final _date = DateFormat('dd-MM-yyyy');

/// "Out 12 / 26-27".
String _numberWithDirection(Challan challan) {
  final direction = challan.isOutward ? 'Out' : 'In';
  return '$direction ${_number(challan)}';
}

/// "12 / 26-27".
String _number(Challan challan) =>
    '${challan.number} / ${shortFinancialYearLabel(challan.financialYear)}';

/// The challans grouped under their printed name, as the old export did:
/// names in plain (case-sensitive) order; within one, outward challans then
/// inward, each newest first (the order the old search returned them in).
List<MapEntry<String, List<Challan>>> _byPrintedName(List<Challan> challans) {
  int newestFirst(Challan a, Challan b) {
    final byDate = b.challanDate.compareTo(a.challanDate);
    if (byDate != 0) return byDate;
    return b.number.compareTo(a.number);
  }

  final ordered = [
    ...challans.where((c) => c.isOutward).toList()..sort(newestFirst),
    ...challans.where((c) => !c.isOutward).toList()..sort(newestFirst),
  ];
  final groups = <String, List<Challan>>{};
  for (final challan in ordered) {
    groups.putIfAbsent(challan.nameOnChallan, () => []).add(challan);
  }
  return groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
}

/// "2 SET", or "2 " with no unit — the old export always added the space.
String _quantity(int quantity, String? unit) => '$quantity ${unit ?? ''}';

/// Every item of every challan, one row each, under a grey heading row per
/// printed name. Cancelled challans' rows are red. [challans] need items.
List<XlsxRow> detailedExportRows(List<Challan> challans) {
  const headings = [
    'Date',
    'Challan No.',
    'Description',
    'Qty',
    'Serial',
    'Bill No.',
    'Additional Description',
    'Notes',
  ];
  return [
    const XlsxRow(headings),
    for (final group in _byPrintedName(challans)) ...[
      XlsxRow([group.key], style: XlsxRowStyle.group, mergeAcross: true),
      for (final challan in group.value)
        for (final item in challan.items)
          XlsxRow(
            [
              _date.format(challan.challanDate),
              _numberWithDirection(challan),
              item.description,
              _quantity(item.quantity, item.unit),
              item.serial ?? '',
              challan.billNumber ?? 'NA',
              item.additionalDescription ?? '',
              challan.notes ?? '',
            ],
            style: challan.isCancelled
                ? XlsxRowStyle.highlighted
                : XlsxRowStyle.plain,
          ),
    ],
  ];
}

/// One row per challan, oldest first, numbered.
List<XlsxRow> indexExportRows(List<Challan> challans) {
  final byDate = List.of(challans)
    ..sort((a, b) {
      final byDay = a.challanDate.compareTo(b.challanDate);
      if (byDay != 0) return byDay;
      return a.number.compareTo(b.number);
    });
  return [
    const XlsxRow(['S. No', 'Date', 'Challan No.', 'Buyer']),
    for (final (index, challan) in byDate.indexed)
      XlsxRow([
        '${index + 1}',
        _date.format(challan.challanDate),
        _number(challan),
        challan.nameOnChallan,
      ]),
  ];
}

Uint8List buildDetailedExport(List<Challan> challans) => buildXlsx(
  sheetName: 'Challans',
  columnCount: 8,
  rows: detailedExportRows(challans),
);

Uint8List buildIndexExport(List<Challan> challans) => buildXlsx(
  sheetName: 'Index',
  columnCount: 4,
  rows: indexExportRows(challans),
);
