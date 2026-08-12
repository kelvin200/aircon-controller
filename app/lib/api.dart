import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

// Server base URL. No committed value and no default — the APK build MUST
// pass it:
//
//	flutter build apk --dart-define=API_BASE=http://<router-ip>:<port>
const _base = String.fromEnvironment('API_BASE');

List<Map<String, dynamic>> buildAutoFollowUpSchedules(DateTime baseTime) {
  final fanChangeAt = baseTime.add(const Duration(minutes: 30));
  final turnOffAt = baseTime.add(const Duration(hours: 2));

  return [
    {
      'fireAt': fanChangeAt.millisecondsSinceEpoch ~/ 1000,
      'fan': 'low',
    },
    {
      'fireAt': turnOffAt.millisecondsSinceEpoch ~/ 1000,
      'state': 'off',
    },
  ];
}

Future<SystemStatus> getStatus() async {
  final resp = await http.get(Uri.parse('$_base/status'));
  if (resp.statusCode < 200 || resp.statusCode >= 300) throw Exception('API GET /status ${resp.statusCode}');
  return SystemStatus.fromJson(jsonDecode(resp.body));
}

/// Maps zone id (z01-z09) to its display name from the backend status
/// payload. The e-zone unit supplies the real name; when one is missing we
/// fall back to the upper-cased zone id (e.g. "Z05") so no private/identifying
/// name is hard-coded in the app.
Map<String, String> zoneNamesFromStatus(SystemStatus status) =>
    status.zones.map((id, zone) => MapEntry(id, zone.name.isEmpty ? id.toUpperCase() : zone.name));

/// Fetches the current zone id -> display name map from the backend.
Future<Map<String, String>> getZoneNames() async => zoneNamesFromStatus(await getStatus());

Future<void> postSystem(Map<String, dynamic> body) async {
  final resp = await http.post(
    Uri.parse('$_base/system'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  if (resp.statusCode < 200 || resp.statusCode >= 300) throw Exception('API POST /system ${resp.statusCode}');
}

Future<void> postZone(String zoneId, Map<String, dynamic> body) async {
  final resp = await http.post(
    Uri.parse('$_base/zones/$zoneId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  if (resp.statusCode < 200 || resp.statusCode >= 300) throw Exception('API POST /zones/$zoneId ${resp.statusCode}');
}

Future<List<ScheduleEntry>> getSchedules() async {
  final resp = await http.get(Uri.parse('$_base/schedules'));
  final List<dynamic> list = jsonDecode(resp.body);
  return list.map((e) => ScheduleEntry.fromJson(e)).toList();
}

Future<ScheduleEntry> postSchedule(Map<String, dynamic> body) async {
  final resp = await http.post(
    Uri.parse('$_base/schedules'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  if (resp.statusCode < 200 || resp.statusCode >= 300) throw Exception('API POST /schedules ${resp.statusCode}');
  return ScheduleEntry.fromJson(jsonDecode(resp.body));
}

Future<void> deleteSchedule(int id) async {
  final resp = await http.delete(Uri.parse('$_base/schedules/$id'));
  if (resp.statusCode < 200 || resp.statusCode >= 300) throw Exception('API DELETE /schedules/$id ${resp.statusCode}');
}

Future<void> deletePastSchedules() async {
  final resp = await http.delete(Uri.parse('$_base/schedules/past'));
  if (resp.statusCode < 200 || resp.statusCode >= 300) throw Exception('API DELETE /schedules/past ${resp.statusCode}');
}

Future<List<AppError>> getErrors() async {
  final resp = await http.get(Uri.parse('$_base/errors'));
  final List<dynamic> list = jsonDecode(resp.body);
  return list.map((e) => AppError.fromJson(e)).toList();
}
