import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state_model.dart';
import '../models/planner_config_model.dart';

const _stateKey = 'r1999_app_state_v2';
const _snapshotKey = 'r1999_daily_plan_snapshot';

class StorageServiceV2 {
  static Future<AppState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null) return null;
    return AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveState(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state.toJson()));
  }

  static Future<void> deleteState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
  }

    static Future<void> saveSnapshot(List<Map<String, dynamic>> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKey, jsonEncode(snapshot));
  }

  static Future<List<Map<String, dynamic>>?> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null) return null;
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> deleteSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey);
  }

  static AppState createDefaultState() {
    return AppState(
      plannerConfig: PlannerConfig(
        patch: PatchInfo(
          tanggalMulai: DateTime.now().toIso8601String().substring(0, 10),
          tanggalAkhir: DateTime.now().add(const Duration(days: 20)).toIso8601String().substring(0, 10),
        ),
        energiPerHari: 100,
        gameDayResetHour: 17,
        mode: PlannerMode.rata,
      ),
      resources: [],
      activities: [],
      activitySelesaiHariIni: [],
      hariIniGameDate: '',
      stokAwalHari: {},
      roundHariIniPerActivity: {},
      taskHariIniSudahSelesaiSemua: false,
      history: [],
    );
  }
}
