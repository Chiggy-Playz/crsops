import 'package:flutter/material.dart';

const employeeColorPalette = <int>[
  0xFFE57373, 0xFFF06292, 0xFFBA68C8, 0xFF64B5F6,
  0xFF4DB6AC, 0xFF81C784, 0xFFFFD54F, 0xFFFF8A65,
];

class EmployeeColorPicker extends StatelessWidget {
  const EmployeeColorPicker({super.key, required this.selectedColor, required this.onChanged});

  final int selectedColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: employeeColorPalette.map((color) {
        final selected = color == selectedColor;
        return GestureDetector(
          onTap: () => onChanged(color),
          child: CircleAvatar(
            backgroundColor: Color(color),
            radius: selected ? 20 : 16,
            child: selected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }
}
