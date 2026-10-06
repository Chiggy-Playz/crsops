import 'dart:io';

import 'package:crs_ops/modules/challans/models/challan_direction.dart';
import 'package:crs_ops/modules/challans/models/challan_item.dart';
import 'package:crs_ops/modules/challans/pdf/amount_in_words.dart';
import 'package:crs_ops/modules/challans/pdf/challan_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_challan_repository.dart';

/// Pages in a PDF, counted from its page objects.
int _pageCount(List<int> bytes) =>
    RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(bytes)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('amountInWords', () {
    test('Indian grouping, no "and"', () {
      expect(amountInWords(0), 'Zero');
      expect(amountInWords(7), 'Seven');
      expect(amountInWords(15), 'Fifteen');
      expect(amountInWords(40), 'Forty');
      expect(amountInWords(105), 'One Hundred Five');
      expect(amountInWords(50000), 'Fifty Thousand');
      expect(amountInWords(150025), 'One Lakh Fifty Thousand Twenty Five');
      expect(amountInWords(1000000), 'Ten Lakh');
      expect(amountInWords(12300000), 'One Crore Twenty Three Lakh');
      expect(amountInWords(1200000000), 'One Hundred Twenty Crore');
    });
  });

  group('challan PDF', () {
    late ChallanPdfAssets assets;

    setUpAll(() async => assets = await ChallanPdfAssets.load());

    final challan = fakeChallan(id: 'c', number: 12).copyWith(
      declaredValue: 150000,
      vehicleNumber: 'dl1c1234',
      gstin: '07AACCV3676J1ZY',
      items: [
        const ChallanItem(
          description: 'Dell Latitude 5420',
          additionalDescription: 'i5 / 16GB / 512GB SSD',
          serial: 'abc123',
          quantity: 2,
          unit: 'set',
        ),
        const ChallanItem(description: 'Mouse', quantity: 2),
      ],
    );

    test('one page per copy; unticked is one page', () async {
      for (final copies in ChallanCopies.values) {
        final bytes = await buildChallanPdf(
          challan,
          copies: copies,
          assets: assets,
        );
        expect(_pageCount(bytes), copies.count, reason: copies.name);
      }
    });

    test('more than a page of items continues on another page', () async {
      final many = challan.copyWith(
        items: [
          for (var i = 0; i < itemsPerPage + 3; i++)
            ChallanItem(description: 'Item $i', quantity: 1),
        ],
      );
      final bytes = await buildChallanPdf(
        many,
        copies: ChallanCopies.three,
        assets: assets,
      );
      expect(_pageCount(bytes), 6);
    });

    test('a cancelled inward challan still builds', () async {
      final bytes = await buildChallanPdf(
        challan.copyWith(
          direction: ChallanDirection.inward,
          cancelledAt: DateTime(2026),
        ),
        copies: ChallanCopies.one,
        assets: assets,
      );
      expect(_pageCount(bytes), 1);
    });

    test('file name', () {
      expect(challanPdfFileName(challan), startsWith('12_'));
      expect(challanPdfFileName(challan), endsWith('_VEGA CORPORATE.pdf'));
      expect(
        challanPdfFileName(
          challan.copyWith(
            direction: ChallanDirection.inward,
            nameOnChallan: 'A/B',
          ),
        ),
        endsWith('_A B.pdf'),
      );
    });

    // To look at it: CHALLAN_PDF_OUT=/tmp/x.pdf flutter test this file.
    test('writes a sample when asked', () async {
      final out = Platform.environment['CHALLAN_PDF_OUT'];
      if (out == null) return;
      final bytes = await buildChallanPdf(
        challan.copyWith(cancelledAt: DateTime(2026)),
        copies: ChallanCopies.two,
        assets: assets,
      );
      File(out).writeAsBytesSync(bytes);
    });
  });
}
