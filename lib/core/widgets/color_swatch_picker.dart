import 'package:flutter/material.dart';

/// Curated palette instead of a full color wheel — this app only needs a
/// handful of clearly-distinct, readable status/event colors, not arbitrary
/// custom ones.
const kSwatchColors = <String>[
  '#4CAF50', // green
  '#F44336', // red
  '#2196F3', // blue
  '#FF9800', // orange
  '#9C27B0', // purple
  '#009688', // teal
  '#FFC107', // amber
  '#795548', // brown
  '#607D8B', // blue grey
];

Color _fromHex(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final hex in kSwatchColors)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onChanged(hex),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _fromHex(hex),
                shape: BoxShape.circle,
                border: selectedHex == hex
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3,
                      )
                    : null,
              ),
              child: selectedHex == hex
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
      ],
    );
  }
}
