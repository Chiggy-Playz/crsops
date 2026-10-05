import 'package:flutter/material.dart';

import '../utils/status_metadata.dart';

/// Curated palette instead of a full color wheel — this app only needs a
/// handful of clearly-distinct, readable status/event colors, not arbitrary
/// custom ones. Names are what screen readers announce.
const _swatches = <({String hex, String name})>[
  (hex: '#4CAF50', name: 'Green'),
  (hex: '#F44336', name: 'Red'),
  (hex: '#2196F3', name: 'Blue'),
  (hex: '#FF9800', name: 'Orange'),
  (hex: '#9C27B0', name: 'Purple'),
  (hex: '#009688', name: 'Teal'),
  (hex: '#FFC107', name: 'Amber'),
  (hex: '#795548', name: 'Brown'),
  (hex: '#607D8B', name: 'Blue grey'),
];

class ColorSwatchPicker extends StatelessWidget {
  const ColorSwatchPicker({
    super.key,
    required this.selectedHex,
    required this.onChanged,
  });

  final String? selectedHex;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedBorder = Border.all(
      color: Theme.of(context).colorScheme.onSurface,
      width: 3,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final swatch in _swatches)
          Semantics(
            label: swatch.name,
            button: true,
            selected: selectedHex == swatch.hex,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(swatch.hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorFor(swatch.hex),
                  shape: BoxShape.circle,
                  border: selectedHex == swatch.hex ? selectedBorder : null,
                ),
                child: selectedHex == swatch.hex
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
