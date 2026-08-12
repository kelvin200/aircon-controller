import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/gradient_action.dart';
import '../widgets/panel.dart';
import '../widgets/selection_segmented_buttons.dart';

SystemStatus buildProjectedStatus({
  required SystemStatus currentStatus,
  required List<ScheduleEntry> pendingSchedules,
  required DateTime targetTime,
}) {
  var projected = SystemStatus(
    state: currentStatus.state,
    mode: currentStatus.mode,
    fan: currentStatus.fan,
    setTemp: currentStatus.setTemp,
    zones: currentStatus.zones.map((zoneId, zone) => MapEntry(
        zoneId,
        ZoneInfo(
          name: zone.name,
          state: zone.state,
          setTemp: zone.setTemp,
          measuredTemp: zone.measuredTemp,
          value: zone.value,
        ))),
  );

  final targetEpoch = targetTime.millisecondsSinceEpoch ~/ 1000;
  final relevantSchedules = pendingSchedules
      .where((entry) => entry.firedAt == null && entry.fireAt <= targetEpoch)
      .toList()
    ..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  for (final entry in relevantSchedules) {
    final nextZones = Map<String, ZoneInfo>.from(projected.zones);
    if (entry.zones != null) {
      for (final zoneEntry in entry.zones!.entries) {
        final existingZone = nextZones[zoneEntry.key];
        if (existingZone == null) continue;
        nextZones[zoneEntry.key] = ZoneInfo(
          name: existingZone.name,
          state: zoneEntry.value.state ?? existingZone.state,
          setTemp: existingZone.setTemp,
          measuredTemp: existingZone.measuredTemp,
          value: zoneEntry.value.value ?? existingZone.value,
        );
      }
    }

    projected = SystemStatus(
      state: entry.state ?? projected.state,
      mode: entry.mode ?? projected.mode,
      fan: entry.fan ?? projected.fan,
      setTemp: entry.setTemp ?? projected.setTemp,
      zones: nextZones,
    );
  }

  return projected;
}

class AddScheduleSheet extends StatefulWidget {
  const AddScheduleSheet({super.key});

  @override
  State<AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<AddScheduleSheet> {
  DateTime _dateTime = DateTime.now().add(const Duration(minutes: 5));
  SystemStatus? _currentStatus;
  List<ScheduleEntry> _pendingSchedules = [];
  String? _state; // null=not set, 'on', 'off'
  String? _mode;
  String? _fan;
  double? _setTemp;
  final Map<String, String> _zones = {}; // zoneId -> 'open'|'close'
  final Map<String, double> _zoneValues = {}; // zoneId -> value 0-100

  String? _initialState;
  String? _initialMode;
  String? _initialFan;
  double? _initialSetTemp;
  final Map<String, String> _initialZones = {};
  final Map<String, double> _initialZoneValues = {};

  static const _zoneKeys = [
    'z01',
    'z02',
    'z03',
    'z04',
    'z05',
    'z06',
    'z07',
    'z08',
    'z09'
  ];

  /// Display names fetched from the backend; falls back to the upper-cased zone
  /// id. Never hard-coded so no private room names are committed.
  final Map<String, String> _zoneNames = {};

  bool _loadingStatus = true;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });

    try {
      final status = await getStatus();
      final allSchedules = await getSchedules();
      final pendingSchedules = allSchedules
          .where((entry) => entry.firedAt == null)
          .toList()
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
      if (!mounted) return;
      setState(() {
        _currentStatus = status;
        _pendingSchedules = pendingSchedules;
      });
      _refreshProjectedValues();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingStatus = false;
      });
    }
  }

  void _refreshProjectedValues() {
    if (_currentStatus == null) return;
    final projected = buildProjectedStatus(
      currentStatus: _currentStatus!,
      pendingSchedules: _pendingSchedules,
      targetTime: _dateTime,
    );
    setState(() {
      _state = projected.state;
      _mode = projected.mode;
      _fan = projected.fan;
      _setTemp = projected.setTemp;
      _zones.clear();
      _zoneValues.clear();
      _initialZones.clear();
      _initialZoneValues.clear();
      for (final zoneId in _zoneKeys) {
        final zoneInfo = projected.zones[zoneId];
        if (zoneInfo != null) {
          _zones[zoneId] = zoneInfo.state;
          _zoneValues[zoneId] = zoneInfo.value.toDouble();
          _initialZones[zoneId] = zoneInfo.state;
          _initialZoneValues[zoneId] = zoneInfo.value.toDouble();
          _zoneNames[zoneId] =
              zoneInfo.name.isEmpty ? zoneId.toUpperCase() : zoneInfo.name;
        }
      }
      _initialState = projected.state;
      _initialMode = projected.mode;
      _initialFan = projected.fan;
      _initialSetTemp = projected.setTemp;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      _dateTime = DateTime(
          date.year, date.month, date.day, _dateTime.hour, _dateTime.minute);
    });
    _refreshProjectedValues();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day,
          time.hour, time.minute);
    });
    _refreshProjectedValues();
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$month/$day/${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _save() async {
    final body = <String, dynamic>{
      'fireAt': _dateTime.millisecondsSinceEpoch ~/ 1000,
    };
    if (_state != null && _state != _initialState) body['state'] = _state;
    if (_mode != null && _mode != _initialMode) body['mode'] = _mode;
    if (_fan != null && _fan != _initialFan) body['fan'] = _fan;
    if (_setTemp != null && _setTemp != _initialSetTemp)
      body['setTemp'] = _setTemp;

    final shouldCreateAutoFollowUpSchedules = _dateTime.isAfter(DateTime.now()) &&
        _state == 'on' &&
        _initialState != 'on';

    final zonesDiff = <String, Map<String, dynamic>>{};
    for (final zoneId in _zoneKeys) {
      final currentState = _zones[zoneId];
      final currentValue = _zoneValues[zoneId];
      final initialState = _initialZones[zoneId];
      final initialValue = _initialZoneValues[zoneId];

      final changedState = currentState != initialState;
      final changedValue = currentValue != initialValue;
      if (!changedState && !changedValue) continue;

      final zoneChange = <String, dynamic>{};
      if (changedState && currentState != null)
        zoneChange['state'] = currentState;
      if (changedValue && currentValue != null)
        zoneChange['value'] = currentValue.toInt();
      if (zoneChange.isNotEmpty) {
        zonesDiff[zoneId] = zoneChange;
      }
    }
    if (zonesDiff.isNotEmpty) {
      body['zones'] = zonesDiff;
    }

    await postSchedule(body);
    if (shouldCreateAutoFollowUpSchedules) {
      for (final schedule in buildAutoFollowUpSchedules(_dateTime)) {
        await postSchedule(schedule);
      }
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isOn = _state == 'on';
    final c = AppColors.of(context);
    final diffColor = c.green;
    final stateDiff =
        _state != null && _initialState != null && _state != _initialState;
    final modeDiff =
        _mode != null && _initialMode != null && _mode != _initialMode;
    final fanDiff = _fan != null && _initialFan != null && _fan != _initialFan;
    final tempDiff = _setTemp != null &&
        _initialSetTemp != null &&
        _setTemp != _initialSetTemp;
    final activeColor =
        isOn ? Theme.of(context).colorScheme.primary : c.textMuted;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Add Schedule',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    TextButton(
                      key: const Key('schedule-cancel'),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 96,
                      child: GradientButton(
                        key: const Key('schedule-save'),
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date/time
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('schedule-pick-date'),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_formatDate(_dateTime)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('schedule-pick-time'),
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_formatTime(_dateTime)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Previewing the system state at the selected time based on pending schedules up to that point.',
              style: TextStyle(color: c.textBody, fontSize: 12),
            ),
            const SizedBox(height: 12),

            if (_loadingStatus)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (_statusError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Failed to load status: $_statusError',
                    style: TextStyle(color: c.coral)),
              ),

            // State
            Text('State',
                style: TextStyle(color: stateDiff ? diffColor : null)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('On / Off'),
              value: _state == 'on',
              onChanged: (v) => setState(() {
                _state = v ? 'on' : 'off';
              }),
              secondary: Icon(Icons.power_settings_new,
                  color: stateDiff ? diffColor : null),
              activeThumbColor: stateDiff ? diffColor : null,
              activeTrackColor:
                  stateDiff ? diffColor.withValues(alpha: 0.3) : null,
              key: const Key('schedule-state-switch'),
            ),
            const SizedBox(height: 8),

            SelectionSegmentedButtons(
              key: const Key('schedule-mode'),
              label: 'Mode',
              options: const ['cool', 'heat', 'vent'],
              selectedValue: _mode,
              isEnabled: isOn,
              textTransform: (option) => option[0].toUpperCase() + option.substring(1),
              onSelected: (value) => setState(() {
                _mode = value;
              }),
              selectedColor: modeDiff ? diffColor : activeColor,
            ),
            const SizedBox(height: 8),

            SelectionSegmentedButtons(
              key: const Key('schedule-fan'),
              label: 'Fan',
              options: const ['low', 'medium', 'high'],
              selectedValue: _fan,
              isEnabled: isOn,
              textTransform: (option) => option[0].toUpperCase() + option.substring(1),
              onSelected: (value) => setState(() {
                _fan = value;
              }),
              selectedColor: fanDiff ? diffColor : activeColor,
            ),
            const SizedBox(height: 8),

            // Set temp
            Text('Temp',
                style: TextStyle(
                    color: tempDiff ? diffColor : (isOn ? null : c.textMuted))),
            Slider(
              key: const Key('schedule-temp-slider'),
              min: 18,
              max: 25,
              divisions: 7,
              label:
                  _setTemp == null ? 'Not set' : _setTemp!.toInt().toString(),
              value: _setTemp ?? 18,
              activeColor:
                  isOn ? (tempDiff ? diffColor : activeColor) : c.textMuted,
              onChanged: (v) => setState(() {
                _setTemp = v;
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _setTemp == null ? 'Not set' : '${_setTemp!.toInt()}°',
                  key: const Key('schedule-temp-value'),
                  style: TextStyle(
                      color:
                          tempDiff ? diffColor : (isOn ? null : c.textMuted)),
                ),
                TextButton(
                  key: const Key('schedule-temp-clear'),
                  onPressed: () => setState(() {
                    _setTemp = null;
                  }),
                  child: const Text('Clear'),
                  style: ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(
                          tempDiff ? diffColor : (isOn ? null : c.textMuted))),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Zones — same 3-column grid as the Zones page.
            Text('Zones', style: TextStyle(color: isOn ? null : c.textMuted)),
            GridView.count(
              key: const Key('schedule-zone-grid'),
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var i = 0; i < _zoneKeys.length; i++)
                  _ScheduleZoneCell(
                    index: i,
                    zoneId: _zoneKeys[i],
                    name: _zoneNames[_zoneKeys[i]] ?? _zoneKeys[i].toUpperCase(),
                    state: _zones[_zoneKeys[i]] ?? 'close',
                    value: (_zoneValues[_zoneKeys[i]] ?? 0.0).toInt(),
                    diffColor: _zoneHasDiff(_zoneKeys[i]) ? diffColor : null,
                    onToggle: () => setState(() {
                      final zid = _zoneKeys[i];
                      final isOpen = _zones[zid] == 'open';
                      _zones[zid] = isOpen ? 'close' : 'open';
                    }),
                    onValue: (v) => setState(() {
                      _zoneValues[_zoneKeys[i]] = v.toDouble();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ));
  }

  /// True when this zone's state or value differs from the status at fire time.
  bool _zoneHasDiff(String zoneId) {
    final val = _zones[zoneId];
    final sliderValue = _zoneValues[zoneId] ?? 0.0;
    final stateDiff =
        val != null && _initialZones[zoneId] != null && val != _initialZones[zoneId];
    final valueDiff = sliderValue != (_initialZoneValues[zoneId] ?? 0.0);
    return stateDiff || valueDiff;
  }
}

/// A zone cell for the schedule editor, matching the Zones page grid language.
///
/// [diffColor] (when set) tints the active cell to show a projected change.
class _ScheduleZoneCell extends StatelessWidget {
  final int index;
  final String zoneId;
  final String name;
  final String state;
  final int value;
  final Color? diffColor;
  final VoidCallback onToggle;
  final void Function(int value) onValue;

  const _ScheduleZoneCell({
    required this.index,
    required this.zoneId,
    required this.name,
    required this.state,
    required this.value,
    this.diffColor,
    required this.onToggle,
    required this.onValue,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isOpen = state == 'open';
    final active = isOpen;
    // When a diff is shown, the cell is tinted green; otherwise the default
    // accent is muted/dimmed like an inactive cell.
    final accent = diffColor ?? c.textMuted;
    final nameColour = active ? c.textPrimary : c.textMuted;
    final valueColour = active && diffColor == null ? c.textMuted : (active ? accent : c.textMuted);

    return InkWell(
      key: Key('schedule-zone-$index'),
      onTap: onToggle,
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
              name,
              key: Key('schedule-zone-$index-name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: nameColour, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              key: Key('schedule-zone-$index-value'),
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
    var current = value.toDouble();
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
                SectionLabel('$name · Damper'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        key: Key('schedule-zone-$index-slider'),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        value: current,
                        label: current.toInt().toString(),
                        onChanged: (v) => setSheetState(() => current = v),
                        onChangeEnd: (v) {
                          onValue(v.toInt());
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
