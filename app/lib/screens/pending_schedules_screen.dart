import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/gradient_action.dart';
import '../widgets/panel.dart';
import '../widgets/top_progress_bar.dart';
import 'add_schedule_sheet.dart';
import 'all_schedules_screen.dart';

class PendingSchedulesScreen extends StatefulWidget {
  const PendingSchedulesScreen({super.key});

  @override
  State<PendingSchedulesScreen> createState() => _PendingSchedulesScreenState();
}

class _PendingSchedulesScreenState extends State<PendingSchedulesScreen> {
  List<ScheduleEntry> _pending = [];
  String? _error;
  Map<String, String> _zoneNames = {};
  Timer? _pollTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; });
    try {
      final all = await getSchedules();
      final pending = all.where((e) => e.firedAt == null).toList()
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
      final names = await getZoneNames();
      if (!mounted) return;
      setState(() { _pending = pending; _error = null; _isLoading = false; _zoneNames = names; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _delete(int id) async {
    await deleteSchedule(id);
    await _load();
  }

  void _openAdd() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddScheduleSheet(),
    );
    if (result == true) await _load();
  }

  String _formatTime(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return dt.toString().substring(0, 16);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Column(
        children: [
          TopProgressBar(onComplete: _load),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $_error'),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          TopProgressBar(onComplete: _load),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('all-schedules-btn'),
                icon: const Icon(Icons.history),
                label: const Text('All Schedules'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllSchedulesScreen()),
                ),
              ),
            ),
          ),
          Expanded(
            child: _pending.isEmpty
                ? const Center(child: Text('No pending schedules'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: _pending.length,
                    itemBuilder: (ctx, i) {
                      final e = _pending[i];
                      final subtitle = _buildSubtitle(e, i);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Panel(
                          key: Key('schedule-item-$i'),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTime(e.fireAt),
                                      key: Key('schedule-item-$i-time'),
                                      style: monoStyle(context, fontSize: 13),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 4),
                                      subtitle,
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                key: Key('schedule-item-$i-delete'),
                                icon: const Icon(Icons.delete_outline),
                                color: AppColors.of(context).coral,
                                onPressed: () => _delete(e.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: GradientFab(
        key: const Key('add-schedule-fab'),
        icon: Icons.add,
        onPressed: _openAdd,
      ),
    );
  }

  Widget? _buildSubtitle(ScheduleEntry e, int i) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final details = <String>[];
    if (e.state != null) details.add('State: ${e.state}');
    if (e.mode != null) details.add('Mode: ${e.mode}');
    if (e.fan != null) details.add('Fan: ${e.fan}');
    if (e.setTemp != null) details.add('Temp: ${e.setTemp!.toStringAsFixed(1)}°');
    if (e.zones != null && e.zones!.isNotEmpty) {
      details.add('Zones: ${_formatZoneChanges(e.zones!)}');
    }

    final detailText = details.isEmpty
        ? null
        : Text(
            details.join(' · '),
            key: Key('schedule-item-$i-details'),
            style: theme.textTheme.bodyMedium,
          );

    if (i == 0) {
      final minutes = _minutesUntil(e.fireAt);
      final countdown = Text(
        minutes <= 0 ? 'Starts now' : 'Starts in $minutes min',
        key: Key('schedule-item-$i-countdown'),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: c.coral,
        ),
      );
      return detailText == null
          ? countdown
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [countdown, const SizedBox(height: 4), detailText],
            );
    }

    if (detailText == null) {
      return e.state == 'off'
          ? Text('State: off', key: Key('schedule-item-$i-state'), style: theme.textTheme.bodyMedium)
          : null;
    }
    return detailText;
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

  int _minutesUntil(int unixSec) {
    final now = DateTime.now();
    final target = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    final diff = target.difference(now);
    return diff.inMinutes.clamp(0, 9999);
  }
}
