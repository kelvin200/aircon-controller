import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'zone_cell.dart';

/// The 9 fixed zones, in order.
const List<String> zoneIds = ['z01','z02','z03','z04','z05','z06','z07','z08','z09'];

/// Accent colour for a system mode — matches the temperature colour coding.
Color modeAccent(String mode) {
  switch (mode) {
    case 'cool': return AppColors.dark.blue;
    case 'heat': return AppColors.dark.orange;
    case 'vent': return AppColors.dark.green;
    default: return AppColors.dark.violet;
  }
}

/// Glanceable 3-column grid of the 9 fixed zones.
///
/// Presentational: the screen owns state and passes toggle/value handlers.
/// [isOn] selects the active-cell accent: the mode accent when the system is
/// on, black when it is off. Zones are always interactive regardless of [isOn].
class ZoneGrid extends StatelessWidget {
  final SystemStatus status;
  final bool isOn;
  final void Function(String zoneId) onToggle;
  final void Function(String zoneId, int value) onValue;

  const ZoneGrid({
    super.key,
    required this.status,
    this.isOn = true,
    required this.onToggle,
    required this.onValue,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final accent = isOn ? modeAccent(status.mode) : Colors.black;
    return Container(
      key: const Key('zone-grid'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(panelRadius),
        // Whole-grid gradient: mode accent tint fading to the canvas.
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isOn ? 0.16 : 0.05),
            c.canvas.withValues(alpha: 0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: c.hairline),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var i = 0; i < zoneIds.length; i++) _cell(context, zoneIds[i], i),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String zoneId, int index) {
    final z = status.zones[zoneId];
    if (z == null) return const SizedBox.shrink();
    return ZoneCell(
      key: Key('zone-cell-$index'),
      zoneId: zoneId,
      zone: z,
      index: index,
      accent: modeAccent(status.mode),
      isOn: isOn,
      onToggle: onToggle,
      onValue: onValue,
    );
  }
}
