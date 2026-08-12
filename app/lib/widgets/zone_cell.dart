import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'panel.dart';

/// A single zone in the 3-column grid.
///
/// Always interactive (tap toggles open/close; long-press reveals a value
/// slider) regardless of AC power. [accent] is the active-cell colour chosen
/// by the caller (mode accent when on, black when off); [isOn] only affects
/// the grid's gradient tint.
class ZoneCell extends StatelessWidget {
  final String zoneId;
  final ZoneInfo zone;
  final int index;
  final Color accent;
  final bool isOn;
  final void Function(String zoneId) onToggle;
  final void Function(String zoneId, int value) onValue;

  const ZoneCell({
    super.key,
    required this.zoneId,
    required this.zone,
    required this.index,
    required this.accent,
    this.isOn = true,
    required this.onToggle,
    required this.onValue,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isOpen = zone.state == 'open';
    final active = isOpen;
    final nameColour = active ? c.textPrimary : c.textMuted;
    final valueColour = active ? accent : c.textMuted;

    return InkWell(
      onTap: () => onToggle(zoneId),
      onLongPress: () => _showValueSheet(context, index),
      borderRadius: BorderRadius.circular(radiusSm),
      child: Container(
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.22) : c.surface,
          borderRadius: BorderRadius.circular(radiusSm),
          border: Border.all(color: active ? accent.withValues(alpha: 0.8) : c.hairline),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              zone.name,
              key: Key('zone-cell-$index-name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: nameColour, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              '${zone.value}',
              key: Key('zone-cell-$index-value'),
              style: TextStyle(
                color: valueColour,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showValueSheet(BuildContext context, int index) async {
    var current = zone.value.toDouble();
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final c = AppColors.of(context);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('${zone.name} · Damper'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        key: Key('zone-cell-$index-slider'),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        value: current,
                        label: current.toInt().toString(),
                        onChanged: (v) => setSheetState(() => current = v),
                        onChangeEnd: (v) {
                          onValue(zoneId, v.toInt());
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${current.toInt()}%',
                      style: monoStyle(context, fontSize: 18, color: c.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
