import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// How a spreadsheet row looks.
enum XlsxRowStyle {
  plain(0),

  /// Bold: column headings.
  header(1),

  /// Bold on grey: a group heading, like a client's name.
  group(2),

  /// Red fill: a cancelled challan.
  highlighted(3);

  const XlsxRowStyle(this.styleIndex);

  /// Its position in [_stylesXml]'s cellXfs.
  final int styleIndex;
}

class XlsxRow {
  const XlsxRow(
    this.cells, {
    this.style = XlsxRowStyle.plain,
    this.mergeAcross = false,
  });

  final List<String> cells;
  final XlsxRowStyle style;

  /// Merge the row's cells into one spanning every column (group headings).
  final bool mergeAcross;
}

/// The mime type to share an .xlsx file with.
const xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// A one-sheet .xlsx file of text cells. Small on purpose: an .xlsx is a zip
/// of a few XML files, and the exports only need text, a few fills, merged
/// group rows and column widths.
Uint8List buildXlsx({
  required String sheetName,
  required List<double> columnWidths,
  required List<XlsxRow> rows,
}) {
  final archive = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add('[Content_Types].xml', _contentTypesXml);
  add('_rels/.rels', _rootRelsXml);
  add('xl/workbook.xml', _workbookXml(sheetName));
  add('xl/_rels/workbook.xml.rels', _workbookRelsXml);
  add('xl/styles.xml', _stylesXml);
  add('xl/worksheets/sheet1.xml', _sheetXml(columnWidths, rows));

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// "A", "B", … "Z", "AA" for a 0-based column index.
String columnLetter(int index) {
  var letters = '';
  var remaining = index + 1;
  while (remaining > 0) {
    final digit = (remaining - 1) % 26;
    letters = String.fromCharCode(65 + digit) + letters;
    remaining = (remaining - 1) ~/ 26;
  }
  return letters;
}

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    // Control characters other than tab and newline aren't allowed in XML.
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

String _sheetXml(List<double> columnWidths, List<XlsxRow> rows) {
  final columnCount = columnWidths.length;
  final lastColumn = columnLetter(columnCount - 1);
  final sheetRows = StringBuffer();
  final merges = <String>[];

  for (final (index, row) in rows.indexed) {
    final rowNumber = index + 1;
    final style = row.style.styleIndex;
    sheetRows.write('<row r="$rowNumber">');
    // Every column gets a cell so fills cover the whole row.
    for (var column = 0; column < columnCount; column++) {
      final ref = '${columnLetter(column)}$rowNumber';
      final text = column < row.cells.length ? row.cells[column] : '';
      if (text.isEmpty) {
        sheetRows.write('<c r="$ref" s="$style"/>');
      } else {
        sheetRows.write(
          '<c r="$ref" s="$style" t="inlineStr"><is>'
          '<t xml:space="preserve">${_escape(text)}</t></is></c>',
        );
      }
    }
    sheetRows.write('</row>');
    if (row.mergeAcross) merges.add('A$rowNumber:$lastColumn$rowNumber');
  }

  final columns = [
    for (final (index, width) in columnWidths.indexed)
      '<col min="${index + 1}" max="${index + 1}" width="$width" '
          'customWidth="1"/>',
  ].join();
  final mergeXml = merges.isEmpty
      ? ''
      : '<mergeCells count="${merges.length}">'
            '${merges.map((m) => '<mergeCell ref="$m"/>').join()}'
            '</mergeCells>';

  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0">'
      // Keep the heading row in view while scrolling.
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
      '</sheetView></sheetViews>'
      '<cols>$columns</cols>'
      '<sheetData>$sheetRows</sheetData>'
      '$mergeXml'
      '</worksheet>';
}

String _workbookXml(String sheetName) =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets><sheet name="${_escape(sheetName)}" sheetId="1" r:id="rId1"/></sheets>'
    '</workbook>';

const _contentTypesXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
    '</Types>';

const _rootRelsXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
    '</Relationships>';

const _workbookRelsXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '</Relationships>';

// cellXfs, in XlsxRowStyle order: plain, header (bold), group (bold on
// grey #E0E0E0), highlighted (red #FF0000). Wrapped, top-aligned text so
// multi-line cells show in full.
const _stylesXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<fonts count="2">'
    '<font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font>'
    '</fonts>'
    '<fills count="4">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FFE0E0E0"/><bgColor indexed="64"/></patternFill></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FFFF0000"/><bgColor indexed="64"/></patternFill></fill>'
    '</fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="4">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
    '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
    '<xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';
