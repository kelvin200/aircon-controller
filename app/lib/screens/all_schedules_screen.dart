import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/gradient_action.dart';
import '../widgets/panel.dart';
import '../widgets/status_pill.dart';
import '../widgets/top_progress_bar.dart';

class AllSchedulesScreen extends StatefulWidget {
  const AllSchedulesScreen({super.key});

  @override
  State<AllSchedulesScreen> createState() => _AllSchedulesScreenState();
}

class _AllSchedulesScreenState extends State<AllSchedulesScreen> {
  List<ScheduleEntry> _schedules = [];
  String? _error;
  Map<String, String> _zoneNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await getSchedules()
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
      final names = await getZoneNames();
      setState(() { _schedules = all; _error = null; _zoneNames = names; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
  }

  Future<void> _delete(int id) async {
    await deleteSchedule(id);
    await _load();
  }

  Future<void> _clearPast() async {
    await deletePastSchedules();
    await _load();
  }

  String _formatTime(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return dt.toString().substring(0, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('All Schedules'),
        actions: [
          TextButton(
            key: const Key('clear-past-btn'),
            style: dangerButtonStyle(),
            onPressed: _clearPast,
            child: const Text('Clear Past'),
          ),
        ],
      ),
      body: Column(
        children: [
          TopProgressBar(onComplete: _load),
          Expanded(
            child: _error != null
                ? Center(child: Text('Error: $_error'))
                : _schedules.isEmpty
                    ? const Center(child: Text('No schedules'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _schedules.length,
                        itemBuilder: (ctx, i) {
                          final e = _schedules[i];
                          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                          final fired = e.firedAt != null;
                          final failed = !fired && e.fireAt < now;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Opacity(
                              opacity: fired ? 0.6 : 1.0,
                              child: Panel(
                                key: Key('all-schedule-item-$i'),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _statusPill(fired, failed),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatTime(e.fireAt),
                                            key: Key('all-schedule-item-$i-time'),
                                            style: monoStyle(context, fontSize: 13),
                                          ),
                                          if (_buildSubtitle(e, i) != null) ...[
                                            const SizedBox(height: 4),
                                            _buildSubtitle(e, i)!,
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(bool fired, bool failed) {
    final c = AppColors.of(context);
    if (fired) {
      return StatusPill(label: 'Fired', colour: c.green);
    }
    if (failed) {
      return StatusPill(label: 'Missed', colour: c.coral);
    }
    return StatusPill(label: 'Pending', colour: c.blue);
  }

  Widget? _buildSubtitle(ScheduleEntry e, int i) {
    if (e.state == 'off') {
      return Text('State: off', key: Key('all-schedule-item-$i-state'), style: Theme.of(context).textTheme.bodyMedium);
    }
    final parts = <String>[];
    if (e.state != null) parts.add('State: ${e.state}');
    if (e.mode != null) parts.add('Mode: ${e.mode}');
    if (e.fan != null) parts.add('Fan: ${e.fan}');
    if (e.setTemp != null) parts.add('Temp: ${e.setTemp!.toStringAsFixed(1)}°');
    if (e.zones != null && e.zones!.isNotEmpty) {
      parts.add('Zones: ${_formatZoneChanges(e.zones!)}');
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '), key: Key('all-schedule-item-$i-details'), style: Theme.of(context).textTheme.bodyMedium);
  }

  String _formatZoneChanges(Map<String, ZoneChange> zones) {
    return zones.entries.map((entry) {
      final name = _zoneNames[entry.key] ?? entry.key.toUpperCase();
      final change = entry.value;
      final parts = <String>[];
      if (change.state != null) {
        final state = change.state == 'open' ? 'ON' : change.state == 'close' ? 'OFF' : change.state!;
        parts.add(state);
      }
      if (change.value != null) parts.add(change.value!.toString());
      final suffix = parts.isEmpty ? '' : ': ${parts.join(' ')}';
      return '$name$suffix';
    }).join(', ');
  }
}
