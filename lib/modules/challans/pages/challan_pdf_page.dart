import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/widgets/menu_chip.dart';
import '../pdf/challan_pdf.dart';
import '../providers/challan_providers.dart';

/// The challan's PDF, previewed, with print and share buttons and a choice
/// of how many copies (as the old app offered: 1, 2, 3 pages or unticked).
class ChallanPdfPage extends ConsumerStatefulWidget {
  const ChallanPdfPage({super.key, required this.challanId});

  final String challanId;

  @override
  ConsumerState<ChallanPdfPage> createState() => _ChallanPdfPageState();
}

class _ChallanPdfPageState extends ConsumerState<ChallanPdfPage> {
  ChallanCopies _copies = ChallanCopies.three;

  @override
  Widget build(BuildContext context) {
    final challanAsync = ref.watch(challanProvider(widget.challanId));
    final assetsAsync = ref.watch(challanPdfAssetsProvider);
    final challan = challanAsync.value;
    final assets = assetsAsync.value;

    final Widget body;
    final error = challanAsync.error ?? assetsAsync.error;
    if (error != null) {
      body = Center(child: Text('$error'));
    } else if (challan == null || assets == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = PdfPreview(
        // A new key rebuilds the PDF when the copies change.
        key: ValueKey(_copies),
        build: (_) => buildChallanPdf(challan, copies: _copies, assets: assets),
        pdfFileName: challanPdfFileName(challan),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(
          challan == null ? 'Challan PDF' : 'Challan ${challan.numberLabel}',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MenuChip<ChallanCopies>(
              icon: Icons.content_copy_outlined,
              label: _copies.label,
              selected: _copies,
              options: [
                for (final option in ChallanCopies.values)
                  MenuChipOption(option, option.label),
              ],
              onSelected: (copies) => setState(() => _copies = copies),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
