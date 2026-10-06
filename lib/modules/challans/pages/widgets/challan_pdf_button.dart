import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_talker.dart';
import '../../../../core/utils/share_file.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/overflow_menu.dart';
import '../../models/challan.dart';
import '../../pdf/challan_pdf.dart';
import '../../providers/challan_providers.dart';

/// The PDF button on a challan's page: pick how many copies and the PDF is
/// made straight away, no preview. The web downloads it; phones open the
/// share sheet (WhatsApp, print, save).
class ChallanPdfButton extends ConsumerStatefulWidget {
  const ChallanPdfButton({super.key, required this.challan});

  /// With its items loaded.
  final Challan challan;

  @override
  ConsumerState<ChallanPdfButton> createState() => _ChallanPdfButtonState();
}

class _ChallanPdfButtonState extends ConsumerState<ChallanPdfButton> {
  bool _making = false;

  Future<void> _make(ChallanCopies copies) async {
    setState(() => _making = true);
    try {
      final assets = await ref.read(challanPdfAssetsProvider.future);
      final bytes = await buildChallanPdf(
        widget.challan,
        copies: copies,
        assets: assets,
      );
      await shareGeneratedFile(
        bytes: bytes,
        fileName: challanPdfFileName(widget.challan),
        mimeType: 'application/pdf',
      );
    } on Exception catch (error, stackTrace) {
      appTalker.error('Making the challan PDF failed', error, stackTrace);
      showAppSnackBar("Couldn't make the PDF. Try again.");
    } finally {
      if (mounted) setState(() => _making = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_making) {
      return const IconButton(
        onPressed: null,
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final String tooltip;
    if (kIsWeb) {
      tooltip = 'Download PDF';
    } else {
      tooltip = 'Share PDF';
    }

    return OverflowMenu(
      icon: Icons.picture_as_pdf_outlined,
      tooltip: tooltip,
      items: [
        for (final copies in ChallanCopies.values)
          OverflowMenuItem(label: copies.label, onPressed: () => _make(copies)),
      ],
    );
  }
}
