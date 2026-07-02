import 'stage_task_model.dart';
import 'character_plan_model.dart';
import 'material_target_model.dart';

class CharacterUpgradeHistoryEntry {
  String tanggal;
  List<String> stageSelesai;

  CharacterUpgradeHistoryEntry({required this.tanggal, required this.stageSelesai});

  factory CharacterUpgradeHistoryEntry.fromJson(Map<String, dynamic> j) => CharacterUpgradeHistoryEntry(
    tanggal: j['tanggal'],
    stageSelesai: List<String>.from(j['stage_selesai'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'tanggal': tanggal,
    'stage_selesai': stageSelesai,
  };

}

class CharacterUpgradeState {
  List<CharacterPlan> characters;
  List<StageTask> stageTasks;
  List<MaterialTarget> materialTargets;
  int energiPerHari;
  int gameDayResetHour;
  int dailyDust;
  int dailySharpodonty;
  bool wildernessSelesaiHariIni;
  String hariIniGameDate;
  List<CharacterUpgradeHistoryEntry> history;
  List<String> stageSelesaiHariIni;
  Map<String, int> runsHariIniPerStage;

  Map<String, int> autoCompleteSnapshot;

  CharacterUpgradeState({
    required this.characters,
    required this.stageTasks,
    required this.materialTargets,
    required this.energiPerHari,
    required this.gameDayResetHour,
    required this.dailyDust,
    required this.dailySharpodonty,
    required this.wildernessSelesaiHariIni,
    required this.hariIniGameDate,
    required this.history,
    required this.stageSelesaiHariIni,
    required this.runsHariIniPerStage,
    this.autoCompleteSnapshot = const {},
  });

  factory CharacterUpgradeState.fromJson(Map<String, dynamic> j) => CharacterUpgradeState(
    characters: (j['characters'] as List).map((c) => CharacterPlan.fromJson(c)).toList(),
    stageTasks: (j['stage_tasks'] as List).map((s) => StageTask.fromJson(s)).toList(),
    materialTargets: (j['material_targets'] as List).map((m) => MaterialTarget.fromJson(m)).toList(),
    energiPerHari: j['energi_per_hari'] ?? 100,
    gameDayResetHour: j['game_day_reset_hour'] ?? 17,
    dailyDust: j['daily_dust'] ?? 0,
    dailySharpodonty: j['daily_sharpodonty'] ?? 0,
    wildernessSelesaiHariIni: j['wilderness_selesai_hari_ini'] ?? false,
    hariIniGameDate: j['hari_ini_game_date'] ?? '',
    history: (j['history'] as List? ?? []).map((h) => CharacterUpgradeHistoryEntry.fromJson(h)).toList(),
    stageSelesaiHariIni: List<String>.from(j['stage_selesai_hari_ini'] ?? []),
    runsHariIniPerStage: Map<String, int>.from(j['runs_hari_ini_per_stage'] ?? {}),
    autoCompleteSnapshot: Map<String, int>.from(j['auto_complete_snapshot'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'characters': characters.map((c) => c.toJson()).toList(),
    'stage_tasks': stageTasks.map((s) => s.toJson()).toList(),
    'material_targets': materialTargets.map((m) => m.toJson()).toList(),
    'energi_per_hari': energiPerHari,
    'game_day_reset_hour': gameDayResetHour,
    'daily_dust': dailyDust,
    'daily_sharpodonty': dailySharpodonty,
    'wilderness_selesai_hari_ini': wildernessSelesaiHariIni,
    'hari_ini_game_date': hariIniGameDate,
    'history': history.map((h) => h.toJson()).toList(),
    'stage_selesai_hari_ini': stageSelesaiHariIni,
    'runs_hari_ini_per_stage': runsHariIniPerStage,
    'auto_complete_snapshot': autoCompleteSnapshot,
  };

  MaterialTarget? getMaterialTarget(String nama) {
    for (final m in materialTargets) {
      if (m.nama == nama) return m;
    }
    return null;
  }
}
