import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_upgrade_state_model.dart';
import '../models/character_plan_model.dart';
import '../models/stage_task_model.dart';
import '../models/material_target_model.dart';

const _stateKey = 'r1999_character_upgrade_state';

class StorageServiceCharacter {
  static Future<CharacterUpgradeState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null) return null;
    return CharacterUpgradeState.fromJson(jsonDecode(raw));
  }

  static Future<void> saveState(CharacterUpgradeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state.toJson()));
  }

  static Future<void> deleteState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
  }

  static Future<void> saveSnapshot(String snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('r1999_character_snapshot', snapshot);
  }

  static Future<String?> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('r1999_character_snapshot');
  }

  static Future<void> deleteSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('r1999_character_snapshot');
  }

  static CharacterUpgradeState createDefaultState(int energiPerHari, int resetHour) {
    return CharacterUpgradeState(
      characters: [],
      stageTasks: [],
      materialTargets: [],
      energiPerHari: energiPerHari,
      gameDayResetHour: resetHour,
      dailyDust: 0,
      dailySharpodonty: 0,
      wildernessSelesaiHariIni: false,
      hariIniGameDate: '',
      history: [],
      stageSelesaiHariIni: [],
      runsHariIniPerStage: {},
    );
  }
}
