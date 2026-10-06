import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crs_ops/core/export/xlsx_writer.dart';
import 'package:crs_ops/modules/challans/export/challan_exports.dart';
import 'package:crs_ops/modules/challans/models/challan_direction.dart';
import 'package:crs_ops/modules/challans/models/challan_item.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_challan_repository.dart';

final _vega1 = fakeChallan(id: 'a', number: 12, date: DateTime(2026, 10, 6))
    .copyWith(
      billNumber: 'B-7',
      notes: 'urgent',
      items: const [
        ChallanItem(
          description: 'LAPTOP',
          serial: 'S1',
          quantity: 2,
          unit: 'SET',
        ),
        ChallanItem(description: 'MOUSE', quantity: 1),
      ],
    );
final _vega2 = fakeChallan(
  id: 'b',
  number: 3,
  direction: ChallanDirection.inward,
  date: DateTime(2026, 4, 2),
).copyWith(cancelledAt: DateTime(2026, 4, 3));
final _offshoot = fakeChallan(
  id: 'c',
  number: 11,
  clientId: 'o',
  clientName: 'Offshoot',
  date: DateTime(2026, 5, 1),
);

void main() {
  test(
    'detailed: a heading per printed name, a row per item, cancelled red',
    () {
      final rows = detailedExportRows([_vega1, _vega2, _offshoot]);

      expect(rows.first.style, XlsxRowStyle.plain);
      expect(rows.first.cells, [
        'Date',
        'Challan No.',
        'Description',
        'Qty',
        'Serial',
        'Bill No.',
        'Additional Description',
        'Notes',
      ]);
      // Grouped by printed name; OFFSHOOT sorts before VEGA CORPORATE.
      expect(rows[1].cells, ['OFFSHOOT']);
      expect(rows[1].style, XlsxRowStyle.group);
      expect(rows[1].mergeAcross, isTrue);
      expect(rows[3].cells, ['VEGA CORPORATE']);
      expect(rows[4].cells, [
        '06-10-2026',
        'Out 12 / 26-27',
        'LAPTOP',
        '2 SET',
        'S1',
        'B-7',
        '',
        'urgent',
      ]);
      // No unit: the old export still wrote "1 ".
      expect(rows[5].cells.sublist(2, 4), ['MOUSE', '1 ']);
      final cancelledRow = rows[6];
      expect(cancelledRow.cells[1], 'In 3 / 26-27');
      expect(cancelledRow.cells[5], 'NA');
      expect(cancelledRow.style, XlsxRowStyle.highlighted);
    },
  );

  test('detailed: outward before inward under one name, newest first', () {
    final older = fakeChallan(id: 'd', number: 5, date: DateTime(2026, 6, 1));
    final rows = detailedExportRows([older, _vega2, _vega1]);
    expect(rows.skip(2).map((r) => r.cells[1]).toSet().toList(), [
      'Out 12 / 26-27',
      'Out 5 / 26-27',
      'In 3 / 26-27',
    ]);
  });

  test('index: one numbered row per challan, oldest first', () {
    final rows = indexExportRows([_vega1, _vega2, _offshoot]);
    expect(rows.first.cells, ['S. No', 'Date', 'Challan No.', 'Buyer']);
    expect(rows.skip(1).map((r) => r.cells), [
      ['1', '02-04-2026', '3 / 26-27', 'VEGA CORPORATE'],
      ['2', '01-05-2026', '11 / 26-27', 'OFFSHOOT'],
      ['3', '06-10-2026', '12 / 26-27', 'VEGA CORPORATE'],
    ]);
  });

  test('the .xlsx unzips into a workbook with the text and merges', () {
    final bytes = buildDetailedExport([_vega1, _offshoot]);
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();
    expect(
      names,
      containsAll([
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/_rels/workbook.xml.rels',
        'xl/styles.xml',
        'xl/worksheets/sheet1.xml',
      ]),
    );
    final sheet = utf8.decode(
      archive.findFile('xl/worksheets/sheet1.xml')!.content,
    );
    expect(sheet, contains('<t xml:space="preserve">LAPTOP</t>'));
    expect(sheet, contains('<mergeCell ref="A2:H2"/>'));
  });

  test('text is escaped for XML', () {
    final bytes = buildXlsx(
      sheetName: 'S',
      columnCount: 1,
      rows: const [
        XlsxRow(['A & B <C> "D"']),
      ],
    );
    final sheet = utf8.decode(
      ZipDecoder()
          .decodeBytes(bytes)
          .findFile('xl/worksheets/sheet1.xml')!
          .content,
    );
    expect(sheet, contains('A &amp; B &lt;C&gt; &quot;D&quot;'));
  });

  test('column letters', () {
    expect(columnLetter(0), 'A');
    expect(columnLetter(7), 'H');
    expect(columnLetter(25), 'Z');
    expect(columnLetter(26), 'AA');
  });

  // To open it in a spreadsheet app: CHALLAN_XLSX_OUT=/tmp/x.xlsx flutter test
  // this file.
  test('writes a sample when asked', () {
    final out = Platform.environment['CHALLAN_XLSX_OUT'];
    if (out == null) return;
    File(out)
        .writeAsBytesSync(buildDetailedExport([_vega1, _vega2, _offshoot]));
  });
}
