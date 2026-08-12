import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart' as api;
import '../models.dart';
import '../widgets/top_progress_bar.dart';
import '../widgets/zone_grid.dart';

/// Dedicated page for the 9 zones.
///
/// Reuses the same status loading, polling, and optimistic zone-command
/// plumbing as [StatusScreen], but renders only the zone grid — which stays
/// interactive whether the system is on or off.
class ZonesPage extends StatefulWidget {
  final ValueChanged<String?>? onStatus;

  /// Test seams: default to the real API when not provided.
  final Future<SystemStatus> Function()? getStatus;
  final Future<void> Function(String zoneId, Map<String, dynamic> body)? postZone;

  const ZonesPage({super.key, this.onStatus, this.getStatus, this.postZone});

  @override
  State<ZonesPage> createState() => _ZonesPageState();
}

class _ZonesPageState extends State<ZonesPage> {
  SystemStatus? _status;
  String? _error;
  Timer? _pollTimer;
  int _fetchSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_fetchSeq;
    try {
      final s = await (widget.getStatus ?? api.getStatus)();
      if (!mounted || seq != _fetchSeq) return;
      setState(() {
        _status = s;
        _error = null;
      });
      widget.onStatus?.call(s.state);
    } catch (e) {
      if (!mounted || seq != _fetchSeq) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _zoneCmdOptimistic(String zoneId, Map<String, dynamic> body) async {
    if (_status == null) return;
    final prev = _status!;
    final prevZone = prev.zones[zoneId];
    if (prevZone == null) return;
    final newZone = ZoneInfo(
      name: prevZone.name,
      state: body['state'] as String? ?? prevZone.state,
      setTemp: prevZone.setTemp,
      measuredTemp: prevZone.measuredTemp,
      value: body.containsKey('value') ? (body['value'] as num).toInt() : prevZone.value,
    );
    final newZones = Map<String, ZoneInfo>.from(prev.zones);
    newZones[zoneId] = newZone;
    setState(() {
      _status = SystemStatus(
        state: prev.state,
        mode: prev.mode,
        fan: prev.fan,
        setTemp: prev.setTemp,
        zones: newZones,
      );
    });
    try {
      await (widget.postZone ?? api.postZone)(zoneId, body);
    } catch (e) {
      if (mounted) setState(() => _status = prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Column(
        children: [
          TopProgressBar(onComplete: _load),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      );
    }

    final s = _status;
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isOn = s.state == 'on';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ZoneGrid(
        status: s,
        isOn: isOn,
        onToggle: (zoneId) {
          final z = s.zones[zoneId];
          if (z == null) return;
          _zoneCmdOptimistic(zoneId, {'state': z.state == 'open' ? 'close' : 'open'});
        },
        onValue: (zoneId, value) => _zoneCmdOptimistic(zoneId, {'value': value}),
      ),
    );
  }
}
