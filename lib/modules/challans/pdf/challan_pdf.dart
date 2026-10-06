import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../financial_year.dart';
import '../models/challan.dart';
import '../models/challan_item.dart';
import 'amount_in_words.dart';

// The delivery challan as CRS Manager printed it for years, redrawn with the
// `pdf` package. Every position below is the old app's (get_pdf.dart), in
// points from the top-left of the page inside its 5-point margin, so the
// layout matches the old printouts. Additions: items continue onto more
// pages after [itemsPerPage], and the inward variant.

// ── Letterhead ──────────────────────────────────────────────────────────────

const _gstin = 'GSTIN : 07AFUPG3557P1ZM';
const _stateCode = 'State Code : 07';
const _companyName = 'Computer Rental Services';
const _companyAddress = '208 D-3C, SAVITRI NAGAR, NEW DELHI - 110017';
const _companyPhone = 'Phone: 01126014629 / 46605081 Mobile No. : 9999362600';
const _terms = '''
1. CHECKED THE ABOVE CONFIGURATION
2. The system mentioned would be supplied without any software. The hired party will be entirely responsible for the uses of any kind of software installed on the machines. Whether legal or pirated in any circumstances COMPUTER RENTAL SERVICES should not be help responsible for this.
3. You are not allowed to break the seal. Also you are not allowed to open the machine.''';

/// The items one page has room for, as on the old challans (never more
/// than 8 there). More continue on another page.
const itemsPerPage = 8;

/// How many copies to print, as offered by the old app: 1, 2 or 3 pages
/// with the Original / Duplicate / Triplicate box ticked on each, or one
/// page with no box ticked.
enum ChallanCopies {
  one(1, 'Original only'),
  two(2, 'Original + duplicate'),
  three(3, 'Original + duplicate + triplicate'),
  unticked(1, 'One page, nothing ticked');

  const ChallanCopies(this.count, this.label);

  final int count;
  final String label;
}

/// The font with a ₹ sign and the CANCELLED stamp, loaded once from the
/// app's assets.
class ChallanPdfAssets {
  const ChallanPdfAssets({required this.rupeeFont, required this.cancelled});

  final pw.Font rupeeFont;
  final pw.ImageProvider cancelled;

  static Future<ChallanPdfAssets> load() async {
    final font = await rootBundle.load('assets/challans/helvetica.ttf');
    final stamp = await rootBundle.load('assets/challans/cancelled.png');
    return ChallanPdfAssets(
      rupeeFont: pw.Font.ttf(font),
      cancelled: pw.MemoryImage(stamp.buffer.asUint8List()),
    );
  }
}

/// "challan_12_2026-27_VEGA CORPORATE.pdf", like the old file names.
String challanPdfFileName(Challan challan) {
  final direction = challan.isOutward ? '' : 'inward_';
  // Characters Windows and Android don't allow in file names (client names
  // often have a "/") become spaces, then runs of spaces become one.
  final name = challan.nameOnChallan
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return '$direction${challan.number}_'
      '${financialYearLabel(challan.financialYear)}_$name.pdf';
}

/// The challan as a PDF: [copies] sets of pages, each set holding all the
/// items. [challan] must have its items loaded.
Future<Uint8List> buildChallanPdf(
  Challan challan, {
  required ChallanCopies copies,
  required ChallanPdfAssets assets,
}) {
  final document = pw.Document(
    title: 'Challan ${challan.numberLabel}',
    author: _companyName,
  );

  final itemPages = <List<ChallanItem>>[
    for (var start = 0; start < challan.items.length; start += itemsPerPage)
      challan.items.skip(start).take(itemsPerPage).toList(),
  ];
  if (itemPages.isEmpty) itemPages.add(const []);

  for (var copy = 0; copy < copies.count; copy++) {
    for (var pageIndex = 0; pageIndex < itemPages.length; pageIndex++) {
      document.addPage(
        pw.Page(
          pageFormat: _pageFormat,
          margin: const pw.EdgeInsets.all(5),
          build: (_) => _ChallanPage(
            challan: challan,
            items: itemPages[pageIndex],
            firstItemNumber: pageIndex * itemsPerPage + 1,
            isLastPage: pageIndex == itemPages.length - 1,
            tickedCopy: copies == ChallanCopies.unticked ? null : copy,
            assets: assets,
          ).build(),
        ),
      );
    }
  }
  return document.save();
}

/// A4 as the old app's PDF library sized it: 595 × 842 exactly (the `pdf`
/// package's A4 is 595.28 × 841.89, which shifts the right and bottom edges).
const _pageFormat = PdfPageFormat(595, 842);

// Inside the 5-point margin the page is 585 × 832.
const _width = 585.0;
const _height = 832.0;

final _black = PdfColors.black;
const _headerGrey = PdfColor.fromInt(0xFFBFBFBF);

class _ChallanPage {
  _ChallanPage({
    required this.challan,
    required this.items,
    required this.firstItemNumber,
    required this.isLastPage,
    required this.tickedCopy,
    required this.assets,
  });

  final Challan challan;
  final List<ChallanItem> items;
  final int firstItemNumber;
  final bool isLastPage;

  /// 0, 1 or 2: which of Original / Duplicate / Triplicate gets the tick
  /// (the other two get a cross). Null: no marks at all.
  final int? tickedCopy;
  final ChallanPdfAssets assets;

  final _normal = pw.TextStyle(font: pw.Font.helvetica(), fontSize: 12);
  final _bold = pw.TextStyle(font: pw.Font.timesBold(), fontSize: 13);
  final _companyTitle = pw.TextStyle(font: pw.Font.timesBold(), fontSize: 35);
  final _underlined = pw.TextStyle(
    font: pw.Font.helvetica(),
    fontSize: 11,
    decoration: pw.TextDecoration.underline,
  );
  final _boldUnderlined = pw.TextStyle(
    font: pw.Font.helveticaBold(),
    fontSize: 12,
    decoration: pw.TextDecoration.underline,
  );
  final _finePrint = pw.TextStyle(
    font: pw.Font.helvetica(),
    fontSize: 6,
    lineSpacing: 2,
  );
  final _signatureName = pw.TextStyle(
    font: pw.Font.helveticaBold(),
    fontSize: 14,
  );

  /// Text whose top-left corner is at ([left], [top]).
  pw.Widget _text(
    double left,
    double top,
    String text,
    pw.TextStyle style, {
    double width = 400,
  }) => pw.Positioned(
    left: left,
    top: top,
    child: pw.SizedBox(
      width: width,
      child: pw.Text(text, style: style),
    ),
  );

  pw.Widget build() {
    final isOutward = challan.isOutward;
    final date = DateFormat('dd-MMMM-yyyy').format(challan.challanDate);
    final total = challan.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final value = challan.declaredValue;

    return pw.SizedBox(
      width: _width,
      height: _height,
      child: pw.Stack(
        children: [
          pw.CustomPaint(
            size: const PdfPoint(_width, _height),
            painter: (canvas, size) => _paintLines(canvas),
          ),

          // Header.
          _text(15, 40, _gstin, _normal, width: 200),
          _text(
            240,
            40,
            isOutward ? 'Delivery Challan Book' : 'Inward Challan',
            _bold,
            width: 200,
          ),
          _text(484, 40, _stateCode, _normal, width: 100),
          _text(95, 47, _companyName, _companyTitle, width: 500),
          _text(169, 87, _companyAddress, _normal),
          _text(145, 100, _companyPhone, _normal),

          // Client.
          _text(14, 118, 'M/s ', _underlined, width: 40),
          pw.Positioned(left: 10, top: 115, child: _clientBlock()),

          // Challan number, date, copies.
          _text(
            419,
            130,
            'Challan No. : ${challan.number} / '
            '${financialYearLabel(challan.financialYear)}',
            _normal,
            width: 160,
          ),
          _text(419, 160, 'Date : $date', _normal, width: 160),
          _text(419, 190, 'Original for Recipient', _normal, width: 135),
          _text(419, 210, 'Duplicate for Supplier', _normal, width: 135),
          _text(419, 230, 'Triplicate for Transporter', _normal, width: 135),

          // Items.
          pw.Positioned(left: 10, top: 250, child: _itemsTable()),

          if (value != null && isLastPage)
            _text(
              50,
              600,
              'TO WHOMESOEVER IT MAY CONCERN\n'
              'The value of the above materials does not exceed '
              '\u{20B9}${NumberFormat('#,##,##0', 'en_IN').format(value)}/- '
              '(Rs. ${amountInWords(value)} only) inclusive of taxes.',
              pw.TextStyle(font: assets.rupeeFont, fontSize: 12),
              width: 375,
            ),
          _text(
            50,
            660,
            isOutward ? 'Received By : ' : 'Delivered By : ',
            _normal,
            width: 100,
          ),

          // Footer row: vehicle, who delivered/received, total.
          _text(
            50,
            705,
            'Vehicle Number : ${(challan.vehicleNumber ?? '').toUpperCase()}',
            _normal,
            width: 200,
          ),
          _text(
            250,
            705,
            isOutward ? 'Delivered By :' : 'Received By :',
            _normal,
            width: 80,
          ),
          _text(
            330,
            705,
            challan.handledByName.toUpperCase(),
            _boldUnderlined,
            // As wide as the old app allowed: a long name runs on one line,
            // even over "Total", rather than wrapping below the box.
            width: 200,
          ),
          if (isLastPage) ...[
            _text(450, 705, 'Total', _normal, width: 60),
            _text(540, 705, '$total', _normal, width: 35),
          ] else
            _text(450, 705, 'Continued...', _normal, width: 120),

          // Terms and signature.
          _text(15, 725, _terms, _finePrint, width: 345),
          _text(366, 730, 'For', _normal, width: 30),
          _text(388, 728, _companyName, _signatureName, width: 200),
          _text(450, 780, 'Authorised Signatory', _normal, width: 130),

          if (challan.isCancelled)
            pw.Positioned(
              left: 0,
              top: 300,
              // Stretched to fill, as the old app drew it.
              child: pw.Image(
                assets.cancelled,
                width: 500,
                height: 300,
                fit: pw.BoxFit.fill,
              ),
            ),
        ],
      ),
    );
  }

  /// Name, address and GSTIN, one row each with a rule under the first two,
  /// across to the line at x = 415.
  pw.Widget _clientBlock() {
    pw.Widget row(String text, {required bool ruled}) => pw.Container(
      width: 405,
      // Bottom 7: the old grid added its 5-point line spacing after the
      // last line too.
      padding: const pw.EdgeInsets.only(left: 28, top: 3, bottom: 7),
      decoration: ruled
          ? pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _black)),
            )
          : null,
      child: pw.Text(text, style: _normal.copyWith(lineSpacing: 5)),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        row(challan.nameOnChallan, ruled: true),
        row(challan.address, ruled: true),
        row('GST No. : ${challan.gstin ?? ''}', ruled: false),
      ],
    );
  }

  /// #, description (+ second line), serial, quantity. Grey header row; the
  /// item rows have only vertical lines between them.
  pw.Widget _itemsTable() {
    // Measured against the old app's output: its rows were sized for the
    // grid's 14-point font while drawing 12-point text, 2.5 points taller.
    const padding = pw.EdgeInsets.only(left: 5, top: 5, bottom: 4.5);

    pw.Widget cell(String text, {bool center = false}) => pw.Padding(
      padding: padding,
      child: pw.Text(
        text,
        style: _normal,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: _headerGrey,
          border: pw.Border.all(color: _black),
        ),
        children: [
          cell('#', center: true),
          cell('Product Description', center: true),
          cell('Serial', center: true),
          cell('Quantity', center: true),
        ],
      ),
      for (final (index, item) in items.indexed)
        pw.TableRow(
          children: [
            cell('${firstItemNumber + index}', center: true),
            cell(
              [
                item.description.toUpperCase(),
                (item.additionalDescription ?? '').toUpperCase(),
              ].join('\n').trim(),
            ),
            cell((item.serial ?? '').toUpperCase()),
            cell(item.quantityText.toUpperCase(), center: true),
          ],
        ),
    ];

    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(26),
        1: pw.FixedColumnWidth(379),
        2: pw.FixedColumnWidth(100),
        // The rest of the box, as the old grid gave it.
        3: pw.FixedColumnWidth(60),
      },
      border: pw.TableBorder(
        left: pw.BorderSide(color: _black),
        right: pw.BorderSide(color: _black),
        verticalInside: pw.BorderSide(color: _black),
      ),
      children: rows,
    );
  }

  /// The box, rules and copy checkboxes. PDF drawing measures y from the
  /// bottom, so every y is flipped from the old top-down positions.
  void _paintLines(PdfGraphics canvas) {
    double y(double top) => _height - top;

    void line(double x1, double y1, double x2, double y2) {
      canvas
        ..moveTo(x1, y(y1))
        ..lineTo(x2, y(y2));
    }

    void box(double left, double top, double width, double height) =>
        canvas.drawRect(left, y(top + height), width, height);

    canvas
      ..setStrokeColor(_black)
      ..setLineWidth(1);

    box(10, 35, 565, 762); // outer border
    line(10, 115, 575, 115); // under the letterhead
    line(415, 115, 415, 720); // client | challan details
    line(10, 250, 575, 250); // above the items
    line(36, 250, 36, 720); // # | description
    line(515, 250, 515, 720); // serial | quantity
    line(10, 703, 575, 703); // above the footer row
    line(10, 720, 575, 720); // below the footer row
    line(360, 720, 360, 798); // terms | signature

    // Original / Duplicate / Triplicate boxes.
    const boxTops = [190.0, 209.0, 228.0];
    for (final top in boxTops) {
      box(555, top, 14, 15);
    }
    // Stroked before the diagonal tick marks are added: viewers snap paths
    // of only straight lines to the pixel grid, so mixing in diagonals would
    // blur the borders.
    canvas.strokePath();

    final ticked = tickedCopy;
    if (ticked != null) {
      for (final (index, top) in boxTops.indexed) {
        if (index == ticked) {
          line(555, top + 8, 561, top + 15); // tick
          line(561, top + 15, 569, top + 1);
        } else {
          line(555, top, 569, top + 15); // cross
          line(555, top + 15, 569, top);
        }
      }
    }
    canvas.strokePath();
  }
}
