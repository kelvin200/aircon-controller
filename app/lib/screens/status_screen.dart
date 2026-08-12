import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart' as api;
import '../models.dart';
import '../widgets/cards/mode_fan_card.dart';
import '../widgets/cards/power_card.dart';
import '../widgets/cards/temperature_card.dart';
import '../widgets/top_progress_bar.dart';

/// A user command whose optimistic state is still propagating to the server.
///
/// `zoneId` is set for zone commands; system commands compare the full
/// system info (state/mode/fan/setTemp).
class PendingCommand {
  final SystemStatus optimistic;
  final String? zoneId;
  final DateTime issuedAt;

  PendingCommand({required this.optimistic, this.zoneId, required this.issuedAt});
}

/// True when a fetched status confirms [pending] for the fields it changed.
bool pendingConfirmed(PendingCommand pending, SystemStatus fetched) {
  final opt = pending.optimistic;
  final zoneId = pending.zoneId;
  if (zoneId != null) {
    final fz = fetched.zones[zoneId];
    final oz = opt.zones[zoneId];
    if (fz == null || oz == null) return false;
    return fz.state == oz.state && fz.value == oz.value;
  }
  return fetched.state == opt.state &&
      fetched.mode == opt.mode &&
      fetched.fan == opt.fan &&
      fetched.setTemp == opt.setTemp;
}

/// Whether a successful fetch should be held back while [pending] is still
/// propagating: not yet confirmed and inside the grace period.
bool shouldHold(PendingCommand pending, SystemStatus fetched, DateTime now) =>
    !pendingConfirmed(pending, fetched) &&
    now.difference(pending.issuedAt) <= _pendingGrace;

const _pendingGrace = Duration(seconds: 15);

class StatusScreen extends StatefulWidget {
  final ValueChanged<String?>? onStatus;

  /// Test seams: default to the real API when not provided.
  final Future<SystemStatus> Function()? getStatus;
  final Future<void> Function(Map<String, dynamic> body)? postSystem;
  final Future<void> Function(String zoneId, Map<String, dynamic> body)? postZone;
  final Future<void> Function(Map<String, dynamic> body)? postSchedule;

  const StatusScreen({
    super.key,
    this.onStatus,
    this.getStatus,
    this.postSystem,
    this.postZone,
    this.postSchedule,
  });

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  SystemStatus? _status;
  String? _error;
  Timer? _pollTimer;
  bool _isLoading = false;
  int _fetchSeq = 0;
  PendingCommand? _pending;

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
    final seq = ++_fetchSeq;
    setState(() { _isLoading = true; });
    try {
      final s = await (widget.getStatus ?? api.getStatus)();
      if (!mounted || seq != _fetchSeq) return; // superseded by a newer fetch

      final pending = _pending;
      if (pending != null && shouldHold(pending, s, DateTime.now())) {
        return; // command still propagating — keep the optimistic display
      }
      _pending = null; // confirmed, or grace elapsed → apply server truth

      setState(() { _status = s; _error = null; _isLoading = false; });
      widget.onStatus?.call(s.state);
    } catch (e) {
      if (!mounted || seq != _fetchSeq) return;
      if (_pending != null) return; // command still propagating — retry next poll
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _tempColour(String mode) {
    switch (mode) {
      case 'cool': return Colors.blue;
      case 'heat': return Colors.orange;
      case 'vent': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _applySystemOptimistic(Map<String, dynamic> body, SystemStatus Function(SystemStatus) applyLocal) async {
    if (_status == null) return;
    final prev = _status!;
    final optimistic = applyLocal(prev);
    setState(() {
      _status = optimistic;
      _pending = PendingCommand(optimistic: optimistic, issuedAt: DateTime.now());
    });
    widget.onStatus?.call(optimistic.state);
    try {
      await (widget.postSystem ?? api.postSystem)(body);
    } catch (e) {
      if (mounted) setState(() { _status = prev; _pending = null; });
    }
  }

  Future<void> _turnOnWithAutoSchedules() async {
    if (_status == null) return;
    final prev = _status!;
    if (prev.state == 'on') return;

    final optimistic = SystemStatus(
      state: 'on',
      mode: prev.mode,
      fan: prev.fan,
      setTemp: prev.setTemp,
      zones: prev.zones,
    );
    setState(() {
      _status = optimistic;
      _pending = PendingCommand(optimistic: optimistic, issuedAt: DateTime.now());
    });
    widget.onStatus?.call('on');

    // Only the power command itself may revert the optimistic ON.
    try {
      await (widget.postSystem ?? api.postSystem)({'state': 'on'});
    } catch (e) {
      if (mounted) setState(() { _status = prev; _pending = null; });
      return;
    }

    // Follow-up schedules are best-effort: a failure must not revert a
    // power-on that already succeeded.
    try {
      for (final schedule in api.buildAutoFollowUpSchedules(DateTime.now())) {
        await (widget.postSchedule ?? api.postSchedule)(schedule);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create follow-up schedules')),
        );
      }
    }
    // No immediate reconcile here — the guarded poll applies the confirmed
    // state, so a stale immediate read can never flash the UI back to OFF.
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

    if (_status == null) return Column(children: [TopProgressBar(onComplete: _load), const Expanded(child: Center(child: CircularProgressIndicator()))]);

    final s = _status!;
    final isOn = s.state == 'on';
    final tempColor = isOn ? _tempColour(s.mode) : Colors.grey;

    return Column(
      children: [
        TopProgressBar(onComplete: _load),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PowerCard(
                  isOn: isOn,
                  onToggle: () {
                    if (isOn) {
                      _applySystemOptimistic(
                        {'state': 'off'},
                        (prev) => SystemStatus(state: 'off', mode: prev.mode, fan: prev.fan, setTemp: prev.setTemp, zones: prev.zones),
                      );
                    } else {
                      _turnOnWithAutoSchedules();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TemperatureCard(
                  status: s,
                  tempColor: tempColor,
                  onChanged: (v) => setState(() { _status = SystemStatus(state: s.state, mode: s.mode, fan: s.fan, setTemp: v, zones: s.zones); }),
                  onChangeEnd: (v) => _applySystemOptimistic(
                    {'setTemp': v},
                    (prev) => SystemStatus(state: prev.state, mode: prev.mode, fan: prev.fan, setTemp: v, zones: prev.zones),
                  ),
                ),
                const SizedBox(height: 12),
                ModeFanCard(
                  status: s,
                  isOn: isOn,
                  onMode: (value) {
                    if (value == null) return;
                    _applySystemOptimistic(
                      {'state': 'on', 'mode': value},
                      (prev) => SystemStatus(
                        state: prev.state == 'on' ? prev.state : 'on',
                        mode: value,
                        fan: prev.fan,
                        setTemp: prev.setTemp,
                        zones: prev.zones,
                      ),
                    );
                  },
                  onFan: (value) {
                    if (value == null) return;
                    _applySystemOptimistic(
                      {'fan': value},
                      (prev) => SystemStatus(
                        state: prev.state,
                        mode: prev.mode,
                        fan: value,
                        setTemp: prev.setTemp,
                        zones: prev.zones,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
