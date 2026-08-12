import 'package:flutter/material.dart';
import '../../models.dart';
import '../panel.dart';
import '../selection_segmented_buttons.dart';

/// Mode and fan segmented controls card.
class ModeFanCard extends StatelessWidget {
  final SystemStatus status;
  final bool isOn;
  final ValueChanged<String?> onMode;
  final ValueChanged<String?> onFan;

  const ModeFanCard({
    super.key,
    required this.status,
    required this.isOn,
    required this.onMode,
    required this.onFan,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Controls',
      child: Column(
        children: [
          SelectionSegmentedButtons(
            key: const Key('mode-segmented'),
            label: 'Mode',
            options: const ['cool', 'heat', 'vent', 'dry'],
            selectedValue: status.mode,
            isEnabled: isOn,
            textTransform: (o) => o[0].toUpperCase() + o.substring(1),
            onSelected: onMode,
          ),
          const SizedBox(height: 16),
          SelectionSegmentedButtons(
            key: const Key('fan-segmented'),
            label: 'Fan',
            options: const ['low', 'medium', 'high'],
            selectedValue: status.fan,
            isEnabled: isOn,
            textTransform: (o) => o[0].toUpperCase() + o.substring(1),
            onSelected: onFan,
          ),
        ],
      ),
    );
  }
}
