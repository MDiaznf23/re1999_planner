import '../models/character_upgrade_state_model.dart';
import '../models/stage_task_model.dart';

class StageRunHariIni {
  final StageTask stage;
  final int runsHariIni;
  final int energiDipakai;

  StageRunHariIni({
    required this.stage,
    required this.runsHariIni,
    required this.energiDipakai,
  });
}

class CharacterDailyPlanResult {
  final List<StageRunHariIni> items;
  final int energiSisa;
  final bool adaWilderness;

  CharacterDailyPlanResult({
    required this.items,
    required this.energiSisa,
    required this.adaWilderness,
  });
}

CharacterDailyPlanResult hitungCharacterDailyPlan(CharacterUpgradeState state) {
  int energiSisa = state.energiPerHari;
  final items = <StageRunHariIni>[];

  final materialDrivenRuns = _hitungMaterialDrivenRuns(state);

  // Urutan kategori fixed: resource → insight → farming
  final urutan = [StageKategori.resource, StageKategori.insight, StageKategori.farming];

  for (final kategori in urutan) {
    final stages = state.stageTasks
        .where((s) => s.kategori == kategori && !s.selesai)
        .toList()
      ..sort((a, b) => a.prioritas.compareTo(b.prioritas));

    for (final stage in stages) {
      final sisaRunsRencana = stage.totalRuns - stage.runsSelesai;
      if (sisaRunsRencana <= 0) continue;

      int sisaRunsDibutuhkan = sisaRunsRencana;
      if (stage.hasProgressBar && stage.materialsInfo.isNotEmpty) {
        sisaRunsDibutuhkan = materialDrivenRuns[stage.id] ?? 0;
        if (sisaRunsDibutuhkan > sisaRunsRencana) sisaRunsDibutuhkan = sisaRunsRencana;
      }

      if (stage.energiPerRun <= 0) {
        if (sisaRunsDibutuhkan > 0) {
          items.add(StageRunHariIni(
            stage: stage,
            runsHariIni: sisaRunsDibutuhkan,
            energiDipakai: 0,
          ));
        }
        continue;
      }

      if (energiSisa <= 0) break;
      if (sisaRunsDibutuhkan <= 0) continue;

      final maxRunsDariEnergi = energiSisa ~/ stage.energiPerRun;
      final runsHariIni = sisaRunsDibutuhkan < maxRunsDariEnergi ? sisaRunsDibutuhkan : maxRunsDariEnergi;

      if (runsHariIni <= 0) continue;

      final energiDipakai = runsHariIni * stage.energiPerRun;
      energiSisa -= energiDipakai;

      items.add(StageRunHariIni(
        stage: stage,
        runsHariIni: runsHariIni,
        energiDipakai: energiDipakai,
      ));
    }
  }

  return CharacterDailyPlanResult(
    items: items,
    energiSisa: energiSisa,
    adaWilderness: state.dailyDust > 0 || state.dailySharpodonty > 0,
  );
}

Map<String, int> _hitungMaterialDrivenRuns(CharacterUpgradeState state) {
  final hasil = <String, int>{};

  final namaMaterialSemua = <String>{
    for (final s in state.stageTasks)
      if (!s.selesai && s.hasProgressBar)
        for (final m in s.materialsInfo) m.nama,
  };

  for (final namaMaterial in namaMaterialSemua) {
    final target = state.getMaterialTarget(namaMaterial);
    if (target == null) continue;

    double sisaDefisit = (target.target - target.stok).toDouble();
    if (sisaDefisit <= 0) continue;

    // Kandidat stage penghasil material ini (belum selesai), urut dari
    // paling efisien (output per energi) ke paling boros.
    final kandidat = <StageTask>[
      for (final s in state.stageTasks)
        if (!s.selesai && s.hasProgressBar)
          for (final m in s.materialsInfo)
            if (m.nama == namaMaterial && m.jumlahPerRun > 0) s,
    ];

    kandidat.sort((a, b) {
      final effA = _efisiensiMaterial(a, namaMaterial);
      final effB = _efisiensiMaterial(b, namaMaterial);
      return effB.compareTo(effA); // descending: paling efisien duluan
    });

    for (final s in kandidat) {
      if (sisaDefisit <= 0) break;
      final sisaRencana = s.totalRuns - s.runsSelesai;
      if (sisaRencana <= 0) continue;

      final jumlahPerRun = s.materialsInfo
          .firstWhere((m) => m.nama == namaMaterial)
          .jumlahPerRun;

      final runsButuh = (sisaDefisit / jumlahPerRun).ceil();
      final runsDialokasikan = runsButuh < sisaRencana ? runsButuh : sisaRencana;
      if (runsDialokasikan <= 0) continue;

      final existing = hasil[s.id] ?? 0;
      if (runsDialokasikan > existing) hasil[s.id] = runsDialokasikan;

      sisaDefisit -= runsDialokasikan * jumlahPerRun;
    }
  }

  return hasil;
}

double _efisiensiMaterial(StageTask stage, String namaMaterial) {
  if (stage.energiPerRun <= 0) return double.infinity;
  final jumlahPerRun = stage.materialsInfo
      .firstWhere((m) => m.nama == namaMaterial)
      .jumlahPerRun;
  return jumlahPerRun / stage.energiPerRun;
}
