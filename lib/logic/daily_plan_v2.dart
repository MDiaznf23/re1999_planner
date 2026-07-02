import 'dart:math';
import '../models/app_state_model.dart';
import '../models/activity_model.dart';
import '../models/planner_config_model.dart';
import 'game_day.dart';

class PlanResultItem {
  final Activity activity;
  final int round;
  final int energi;
  final String hasilText;
  PlanResultItem({
    required this.activity,
    required this.round,
    required this.energi,
    required this.hasilText,
  });
}

class DailyPlanResult {
  final List<PlanResultItem> items;
  final int energiSisa;
  final List<String> peringatan;
  DailyPlanResult({required this.items, required this.energiSisa, required this.peringatan});
}

String _formatHasil(Activity act, int round, AppState state) {
  if (round <= 0) return 'Tidak dikerjakan';
  final parts = <String>[];
  for (final h in act.hasil) {
    final res = state.getResourceById(h.resourceId);
    final nama = res?.nama ?? h.resourceId;
    parts.add('+${h.jumlahPerRound * round} $nama');
  }
  return parts.join(', ');
}

class _AlokasiSatuHari {
  final Activity activity;
  final int round;
  final int energi;
  _AlokasiSatuHari(this.activity, this.round, this.energi);
}

List<_AlokasiSatuHari> _hitungAlokasiSatuHari({
  required List<Activity> sortedActivities,
  required Map<String, int> stokMap,
  required Map<String, int> targetMap,
  required int energiPerHari,
  required PlannerMode mode,
  required int sisaHariUntukRata,
}) {
  int energiSisa = energiPerHari;
  final sisaHariV = max(sisaHariUntukRata, 1);
  final hasil = <_AlokasiSatuHari>[];

  for (final act in sortedActivities) {
    if (act.isGratis) {
      final round = act.maxRoundPerHari ?? 1;
      hasil.add(_AlokasiSatuHari(act, round, 0));
      for (final h in act.hasil) {
        stokMap[h.resourceId] = (stokMap[h.resourceId] ?? 0) + h.jumlahPerRound * round;
      }
      continue;
    }

    int maxRoundDibutuhkan = 0;
    for (final h in act.hasil) {
      final target = targetMap[h.resourceId];
      if (target == null || h.jumlahPerRound <= 0) continue;
      final stokSaatIni = stokMap[h.resourceId] ?? 0;
      final kekurangan = max(0, target - stokSaatIni);
      final roundButuh = (kekurangan / h.jumlahPerRound).ceil();
      if (roundButuh > maxRoundDibutuhkan) maxRoundDibutuhkan = roundButuh;
    }

    int roundHariIni;
    if (mode == PlannerMode.rata) {
      roundHariIni = (maxRoundDibutuhkan / sisaHariV).ceil();
      final roundMaxEnergi = energiSisa ~/ act.energiPerRound;
      roundHariIni = min(roundHariIni, roundMaxEnergi);
    } else {
      roundHariIni = energiSisa ~/ act.energiPerRound;
      roundHariIni = min(roundHariIni, maxRoundDibutuhkan);
    }
    if (act.maxRoundPerHari != null) {
      roundHariIni = min(roundHariIni, act.maxRoundPerHari!);
    }
    roundHariIni = max(0, roundHariIni);

    final energi = roundHariIni * act.energiPerRound;
    energiSisa -= energi;

    hasil.add(_AlokasiSatuHari(act, roundHariIni, energi));

    for (final h in act.hasil) {
      stokMap[h.resourceId] = (stokMap[h.resourceId] ?? 0) + h.jumlahPerRound * roundHariIni;
    }
  }

  return hasil;
}

List<String> _simulasiSisaPatch({
  required AppState state,
  required List<Activity> sortedActivities,
  required List<_AlokasiSatuHari> alokasiHariIni,
  required int sisaHari,
}) {
  final cfg = state.plannerConfig;
  final targetMap = {for (final r in state.resources) r.id: r.target};

  // Proyeksi stok mulai dari stok SETELAH plan hari ini diterapkan.
  final proyeksiStok = {for (final r in state.resources) r.id: r.stok};
  for (final a in alokasiHariIni) {
    for (final h in a.activity.hasil) {
      proyeksiStok[h.resourceId] = (proyeksiStok[h.resourceId] ?? 0) + h.jumlahPerRound * a.round;
    }
  }

  for (int hariKe = 2; hariKe <= sisaHari; hariKe++) {
    final sisaHariSaatItu = sisaHari - hariKe + 1;
    _hitungAlokasiSatuHari(
      sortedActivities: sortedActivities,
      stokMap: proyeksiStok,
      targetMap: targetMap,
      energiPerHari: cfg.energiPerHari,
      mode: cfg.mode,
      sisaHariUntukRata: sisaHariSaatItu,
    );
  }

  final peringatan = <String>[];
  for (final res in state.resources) {
    final stokAkhir = proyeksiStok[res.id] ?? res.stok;
    final kekuranganAkhir = res.target - stokAkhir;
    if (kekuranganAkhir <= 0) continue;
    peringatan.add(
      '${res.nama}: sampai akhir patch ($sisaHari hari lagi) diperkirakan masih kurang '
      '$kekuranganAkhir dari target ${res.target} (proyeksi stok akhir: $stokAkhir).',
    );
  }
  return peringatan;
}

List<String> hitungPeringatanUntukSnapshot(AppState state, List<PlanResultItem> items) {
  final cfg = state.plannerConfig;
  final sisaHari = hitungSisaHari(cfg.patch.tanggalAkhir, cfg.gameDayResetHour);
  final sortedActivities = List<Activity>.from(state.activities)
    ..sort((a, b) => a.prioritas.compareTo(b.prioritas));
  final alokasiHariIni = [
    for (final i in items) _AlokasiSatuHari(i.activity, i.round, i.energi),
  ];
  return _simulasiSisaPatch(
    state: state,
    sortedActivities: sortedActivities,
    alokasiHariIni: alokasiHariIni,
    sisaHari: max(sisaHari, 1),
  );
}

DailyPlanResult hitungDailyPlan(AppState state) {
  final cfg = state.plannerConfig;
  final sisaHari = hitungSisaHari(cfg.patch.tanggalAkhir, cfg.gameDayResetHour);

  final sortedActivities = List<Activity>.from(state.activities)
    ..sort((a, b) => a.prioritas.compareTo(b.prioritas));

  final stokHariIni = {for (final r in state.resources) r.id: r.stok};
  final targetMap = {for (final r in state.resources) r.id: r.target};

  final alokasiHariIni = _hitungAlokasiSatuHari(
    sortedActivities: sortedActivities,
    stokMap: stokHariIni,
    targetMap: targetMap,
    energiPerHari: cfg.energiPerHari,
    mode: cfg.mode,
    sisaHariUntukRata: sisaHari,
  );

  final items = <PlanResultItem>[];
  int energiSisa = cfg.energiPerHari;
  for (final a in alokasiHariIni) {
    energiSisa -= a.energi;
    items.add(PlanResultItem(
      activity: a.activity,
      round: a.round,
      energi: a.energi,
      hasilText: _formatHasil(a.activity, a.round, state),
    ));
  }

  final peringatan = _simulasiSisaPatch(
    state: state,
    sortedActivities: sortedActivities,
    alokasiHariIni: alokasiHariIni,
    sisaHari: max(sisaHari, 1),
  );

  return DailyPlanResult(items: items, energiSisa: energiSisa, peringatan: peringatan);
}
