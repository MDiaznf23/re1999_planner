import 'package:uuid/uuid.dart';
import '../models/stage_task_model.dart';
import '../models/character_plan_model.dart';
import '../models/material_target_model.dart';
import '../models/character_upgrade_state_model.dart';

const _uuid = Uuid();

class ParsedCharacterData {
  final CharacterPlan plan;
  final List<StageTask> stages;
  final List<MaterialTarget> materialTargets;
  final int dailyDust;
  final int dailySharpodonty;

  ParsedCharacterData({
    required this.plan,
    required this.stages,
    required this.materialTargets,
    required this.dailyDust,
    required this.dailySharpodonty,
  });
}

ParsedCharacterData parseCharacterJson(Map<String, dynamic> json, int startPrioritas) {
  final characterNama = json['character'] ?? json['arcanist'] ?? 'Unknown';
  final characterId = _uuid.v4();

  final plan = CharacterPlan(
    id: characterId,
    characterNama: characterNama,
    totalActivity: (json['total_activity'] ?? 0).round(),
    totalDays: (json['total_days'] ?? 0).toDouble(),
  );

  final stages = <StageTask>[];
  final materialTargets = <MaterialTarget>[];
  final materialTargetMap = <String, MaterialTarget>{};
  int prioritas = startPrioritas;

  // ── Helper parse satu stage ────────────────────────────────────────────────
  StageTask parseStage(Map<String, dynamic> s, StageKategori kategori) {
    final runs = (s['runs'] ?? 1).round();
    final activity = (s['activity'] ?? 0).round();
    final energiPerRun = runs > 0 ? (activity / runs).round() : 0;
    final materials = (s['materials'] as List? ?? [])
        .map((m) => MaterialInfo(
              nama: m['Material'] ?? m['nama'],
              // Simpan sebagai double (fix bug pembulatan-ke-0), pembulatan
              // ke int baru terjadi saat stok benar-benar ditambahkan.
              jumlahPerRun: runs > 0 ? ((m['Quantity'] ?? 0) as num).toDouble() / runs : 0.0,
            ))
        .toList();
    return StageTask(
      id: _uuid.v4(),
      characterNama: characterNama,
      kategori: kategori,
      namaStage: s['stage'] ?? '',
      totalRuns: runs,
      runsSelesai: 0,
      energiPerRun: energiPerRun,
      prioritas: prioritas++,
      materialsInfo: materials,
    );
  }

  // ── Parse resource_stages ──────────────────────────────────────────────────
  for (final s in (json['resource_stages'] as List? ?? [])) {
    final stage = parseStage(s, StageKategori.resource);
    stages.add(stage);
    for (final m in stage.materialsInfo) {
      if (!materialTargetMap.containsKey(m.nama)) {
        final totalNeeded = (json['total_material_needed']?[m.nama] ?? 0).round();
        materialTargetMap[m.nama] = MaterialTarget(nama: m.nama, target: totalNeeded, stok: 0);
      }
    }
  }

  // ── Parse insight_stages ───────────────────────────────────────────────────
  for (final s in (json['insight_stages'] as List? ?? [])) {
    final stage = parseStage(s, StageKategori.insight);
    stages.add(stage);
    for (final m in stage.materialsInfo) {
      if (!materialTargetMap.containsKey(m.nama)) {
        final totalNeeded = (json['total_material_needed']?[m.nama] ?? 0).round();
        materialTargetMap[m.nama] = MaterialTarget(nama: m.nama, target: totalNeeded, stok: 0);
      }
    }
  }

  // ── Parse farming_stages ───────────────────────────────────────────────────
  for (final s in (json['farming_stages'] as List? ?? [])) {
    final stage = parseStage(s, StageKategori.farming);
    stages.add(stage);
    // Farming tidak punya MaterialTarget (no progress bar)
  }

  // ── Wilderness ─────────────────────────────────────────────────────────────
  final wilderness = json['wilderness'] as Map<String, dynamic>? ?? {};
  final dailyDust = (wilderness['daily_dust'] ?? 0).round();
  final dailySharpodonty = (wilderness['daily_sharpodonty'] ?? 0).round();

  if (dailyDust > 0 && !materialTargetMap.containsKey('Dust')) {
    final totalNeeded = (json['total_material_needed']?['Dust'] ?? 0).round();
    materialTargetMap['Dust'] = MaterialTarget(nama: 'Dust', target: totalNeeded, stok: 0);
  }
  if (dailySharpodonty > 0 && !materialTargetMap.containsKey('Sharpodonty')) {
    final totalNeeded = (json['total_material_needed']?['Sharpodonty'] ?? 0).round();
    materialTargetMap['Sharpodonty'] = MaterialTarget(nama: 'Sharpodonty', target: totalNeeded, stok: 0);
  }

  materialTargets.addAll(materialTargetMap.values);

  final materialTargetContrib = {
    for (final mt in materialTargetMap.values) mt.nama: mt.target,
  };
  plan.materialTargetContrib = materialTargetContrib;
  plan.dailyDust = dailyDust;
  plan.dailySharpodonty = dailySharpodonty;

  return ParsedCharacterData(
    plan: plan,
    stages: stages,
    materialTargets: materialTargets,
    dailyDust: dailyDust,
    dailySharpodonty: dailySharpodonty,
  );
}

// Merge karakter baru ke state yang sudah ada
void mergeCharacterToState(CharacterUpgradeState state, ParsedCharacterData data) {
  state.characters.add(data.plan);
  state.stageTasks.addAll(data.stages);

  for (final mt in data.materialTargets) {
    final existing = state.getMaterialTarget(mt.nama);
    if (existing == null) {
      state.materialTargets.add(mt);
    } else {
      existing.target += mt.target;
    }
  }

  // Update wilderness (ambil nilai terbesar dari semua karakter aktif)
  if (data.dailyDust > state.dailyDust) state.dailyDust = data.dailyDust;
  if (data.dailySharpodonty > state.dailySharpodonty) {
    state.dailySharpodonty = data.dailySharpodonty;
  }
}
