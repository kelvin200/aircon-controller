import 'package:flutter/material.dart';
import '../theme.dart';

class SelectionSegmentedButtons extends StatelessWidget {
  const SelectionSegmentedButtons({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.isEnabled,
    this.textTransform,
    this.selectedColor,
  });

  final String label;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;
  final bool isEnabled;
  final String Function(String option)? textTransform;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isEnabled ? theme.colorScheme.primary : AppColors.of(context).textMuted;
    final selectedForegroundColor = Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          segments: options
              .map((option) => ButtonSegment(
                    value: option,
                    label: Text(textTransform?.call(option) ?? option),
                  ))
              .toList(),
          selected: selectedValue == null ? {} : {selectedValue!},
          onSelectionChanged: (selection) {
            final value = selection.isEmpty ? null : selection.first;
            onSelected(value);
          },
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return selectedForegroundColor;
              }
              return isEnabled ? null : AppColors.of(context).textMuted;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return selectedColor ?? activeColor;
              }
              return null;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              return BorderSide(color: states.contains(WidgetState.selected) ? (selectedColor ?? activeColor) : activeColor);
            }),
          ),
        ),
      ],
    );
  }
}
