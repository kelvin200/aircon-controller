import 'package:flutter/material.dart';
import '../../theme.dart';
import '../panel.dart';
import '../status_pill.dart';

/// Power card: system on/off switch with a live status pill in the header row.
class PowerCard extends StatelessWidget {
  final bool isOn;
  final VoidCallback onToggle;

  const PowerCard({super.key, required this.isOn, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return Panel(
      title: 'Power',
      trailing: StatusPill(
        label: isOn ? 'On' : 'Off',
        colour: isOn ? c.green : c.textMuted,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOn ? 'System is running' : 'System is off',
            style: theme.textTheme.bodyMedium,
          ),
          Switch(
            key: const Key('power-switch'),
            activeThumbColor: theme.colorScheme.primary,
            value: isOn,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
