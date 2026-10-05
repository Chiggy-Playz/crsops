import 'package:flutter/material.dart';

/// An outlined, labelled box for non-text inputs (swatches, chips) so they
/// line up with the text fields around them instead of floating under a
/// plain Text label.
class LabelledFieldBox extends StatelessWidget {
  const LabelledFieldBox({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      ),
      child: child,
    );
  }
}
