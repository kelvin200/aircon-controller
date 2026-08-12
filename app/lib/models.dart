class ZoneInfo {
  final String name;
  final String state;
  final double setTemp;
  final double measuredTemp;
  final int value;

  ZoneInfo({
    required this.name,
    required this.state,
    required this.setTemp,
    required this.measuredTemp,
    required this.value,
  });

  factory ZoneInfo.fromJson(Map<String, dynamic> j) => ZoneInfo(
    name: j['name'] as String,
    state: j['state'] as String,
    setTemp: (j['setTemp'] as num).toDouble(),
    measuredTemp: (j['measuredTemp'] as num).toDouble(),
    value: j['value'] as int? ?? 0,
  );
}

class SystemStatus {
  final String state;
  final String mode;
  final String fan;
  final double setTemp;
  final Map<String, ZoneInfo> zones;

  SystemStatus({
    required this.state,
    required this.mode,
    required this.fan,
    required this.setTemp,
    required this.zones,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> j) {
    final info = j['info'] as Map<String, dynamic>;
    final rawZones = j['zones'] as Map<String, dynamic>;
    return SystemStatus(
      state: info['state'] as String,
      mode: info['mode'] as String,
      fan: info['fan'] as String,
      setTemp: (info['setTemp'] as num).toDouble(),
      zones: rawZones.map((k, v) => MapEntry(k, ZoneInfo.fromJson(v as Map<String, dynamic>))),
    );
  }
}

class ZoneChange {
  final String? state;
  final int? value;

  ZoneChange({
    this.state,
    this.value,
  });

  factory ZoneChange.fromJson(Map<String, dynamic> j) => ZoneChange(
    state: j['state'] as String?,
    value: j['value'] as int?,
  );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (state != null) m['state'] = state;
    if (value != null) m['value'] = value;
    return m;
  }
}

class ScheduleEntry {
  final int id;
  final int fireAt;
  final String? state;
  final String? mode;
  final String? fan;
  final double? setTemp;
  final Map<String, ZoneChange>? zones;
  final int? firedAt;

  ScheduleEntry({
    required this.id,
    required this.fireAt,
    this.state,
    this.mode,
    this.fan,
    this.setTemp,
    this.zones,
    this.firedAt,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> j) {
    final rawZones = j['zones'] as Map<String, dynamic>?;
    return ScheduleEntry(
      id: j['id'] as int,
      fireAt: j['fireAt'] as int,
      state: j['state'] as String?,
      mode: j['mode'] as String?,
      fan: j['fan'] as String?,
      setTemp: j['setTemp'] == null ? null : (j['setTemp'] as num).toDouble(),
      zones: rawZones == null
          ? null
          : rawZones.map(
              (k, v) => MapEntry(k, ZoneChange.fromJson(v as Map<String, dynamic>)),
            ),
      firedAt: j['firedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'fireAt': fireAt};
    if (state != null) m['state'] = state;
    if (mode != null) m['mode'] = mode;
    if (fan != null) m['fan'] = fan;
    if (setTemp != null) m['setTemp'] = setTemp;
    if (zones != null) {
      m['zones'] = zones!.map((k, v) => MapEntry(k, v.toJson()));
    }
    return m;
  }
}

class AppError {
  final int id;
  final int occurredAt;
  final String source;
  final String message;

  AppError({
    required this.id,
    required this.occurredAt,
    required this.source,
    required this.message,
  });

  factory AppError.fromJson(Map<String, dynamic> j) => AppError(
    id: j['id'] as int,
    occurredAt: j['occurredAt'] as int,
    source: j['source'] as String,
    message: j['message'] as String,
  );
}
