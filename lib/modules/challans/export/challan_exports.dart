import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../../core/export/xlsx_writer.dart';
import '../challan_search.dart';
import '../financial_year.dart';
import '../models/challan.dart';

// The two spreadsheets the old app exported from search results, with the
// same columns and look.

final _date = DateFormat('dd-MM-yyyy');

/// "Out 12 / 26-27".
String _numberWithDirection(Challan challan) {
  final direction = challan.isOutward ? 'Out' : 'In';
  return '$direction ${_number(challan)}';
}

/// "12 / 26-27".
String _number(Challan challan) =>
    '${challan.number} / ${shortFinancialYearLabel(challan.financialYear)}';

/// Every item of every challan, one row each, under a heading row per
/// client. Cancelled challans' rows are red. [challans] need their items.
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
    const XlsxRow(headings, style: XlsxRowStyle.header),
    for (final group in groupByClient(challans)) ...[
      XlsxRow([group.clientName], style: XlsxRowStyle.group, mergeAcross: true),
      for (final challan in group.challans)
        for (final item in challan.items)
          XlsxRow(
            [
              _date.format(challan.challanDate),
              _numberWithDirection(challan),
              item.description,
              item.quantityText,
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
    const XlsxRow([
      'S. No',
      'Date',
      'Challan No.',
      'Buyer',
    ], style: XlsxRowStyle.header),
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
  columnWidths: const [12, 14, 40, 10, 20, 10, 30, 30],
  rows: detailedExportRows(challans),
);

Uint8List buildIndexExport(List<Challan> challans) => buildXlsx(
  sheetName: 'Index',
  columnWidths: const [7, 12, 14, 45],
  rows: indexExportRows(challans),
);
