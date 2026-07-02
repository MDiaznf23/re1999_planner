import 'stage_task_model.dart';

class CharacterPlan {
  String id;
  String characterNama;
  int totalActivity;
  double totalDays;

  Map<String, int> materialTargetContrib;

  int dailyDust;
  int dailySharpodonty;

  CharacterPlan({
    required this.id,
    required this.characterNama,
    required this.totalActivity,
    required this.totalDays,
    this.materialTargetContrib = const {},
    this.dailyDust = 0,
    this.dailySharpodonty = 0,
  });

  factory CharacterPlan.fromJson(Map<String, dynamic> j) => CharacterPlan(
    id: j['id'],
    characterNama: j['character_nama'],
    totalActivity: j['total_activity'] ?? 0,
    totalDays: (j['total_days'] ?? 0).toDouble(),
    materialTargetContrib: Map<String, int>.from(j['material_target_contrib'] ?? {}),
    dailyDust: j['daily_dust'] ?? 0,
    dailySharpodonty: j['daily_sharpodonty'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'character_nama': characterNama,
    'total_activity': totalActivity,
    'total_days': totalDays,
    'material_target_contrib': materialTargetContrib,
    'daily_dust': dailyDust,
    'daily_sharpodonty': dailySharpodonty,
  };
}
