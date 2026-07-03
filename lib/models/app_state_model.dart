import 'resource_model.dart';
import 'activity_model.dart';
import 'planner_config_model.dart';
import 'history_model.dart';

class AppState {
  PlannerConfig plannerConfig;
  List<Resource> resources;
  List<Activity> activities;
  List<String> activitySelesaiHariIni; // id activity yang sudah dicentang
  String hariIniGameDate;
  Map<String, int> stokAwalHari; // snapshot stok sebelum task hari ini (resourceId -> jumlah) 

  Map<String, int> roundHariIniPerActivity;
  bool taskHariIniSudahSelesaiSemua; // true kalau sudah masuk history
  List<HistoryEntry> history;

  AppState({
    required this.plannerConfig,
    required this.resources,
    required this.activities,
    required this.activitySelesaiHariIni,
    required this.hariIniGameDate,
    required this.stokAwalHari,
    required this.roundHariIniPerActivity,
    required this.taskHariIniSudahSelesaiSemua,
    required this.history,
  });

  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
    plannerConfig: PlannerConfig.fromJson(j['planner_config']),
    resources: (j['resources'] as List).map((r) => Resource.fromJson(r)).toList(),
    activities: (j['activities'] as List).map((a) => Activity.fromJson(a)).toList(),
    activitySelesaiHariIni: List<String>.from(j['activity_selesai_hari_ini'] ?? []),
    hariIniGameDate: j['hari_ini_game_date'] ?? '',
    stokAwalHari: Map<String, int>.from(j['stok_awal_hari'] ?? {}),
    roundHariIniPerActivity: Map<String, int>.from(j['round_hari_ini_per_activity'] ?? {}),
    taskHariIniSudahSelesaiSemua: j['task_hari_ini_sudah_selesai_semua'] ?? false,
    history: (j['history'] as List? ?? []).map((h) => HistoryEntry.fromJson(h)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'planner_config': plannerConfig.toJson(),
    'resources': resources.map((r) => r.toJson()).toList(),
    'activities': activities.map((a) => a.toJson()).toList(),
    'activity_selesai_hari_ini': activitySelesaiHariIni,
    'hari_ini_game_date': hariIniGameDate,
    'stok_awal_hari': stokAwalHari,
    'round_hari_ini_per_activity': roundHariIniPerActivity,
    'task_hari_ini_sudah_selesai_semua': taskHariIniSudahSelesaiSemua,
    'history': history.map((h) => h.toJson()).toList(),
  };

  Resource? getResourceById(String id) {
    for (final r in resources) {
      if (r.id == id) return r;
    }
    return null;
  }

  Activity? getActivityById(String id) {
    for (final a in activities) {
      if (a.id == id) return a;
    }
    return null;
  }
}
