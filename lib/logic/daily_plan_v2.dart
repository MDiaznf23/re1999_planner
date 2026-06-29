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

DailyPlanResult hitungDailyPlan(AppState state) {
  final cfg = state.plannerConfig;
  final sisaHari = hitungSisaHari(cfg.patch.tanggalAkhir, cfg.gameDayResetHour);
  final sisaHariV = max(sisaHari, 1);
  int energiSisa = cfg.energiPerHari;

  final sortedActivities = List<Activity>.from(state.activities)
    ..sort((a, b) => a.prioritas.compareTo(b.prioritas));

  final items = <PlanResultItem>[];
  final peringatan = <String>[];

  if (cfg.mode == PlannerMode.rata) {
    // ── MODE RATA ──────────────────────────────────────────────────────────
    for (final act in sortedActivities) {
      if (act.isGratis) {
        final round = act.maxRoundPerHari ?? 1;
        items.add(PlanResultItem(
          activity: act, round: round, energi: 0,
          hasilText: _formatHasil(act, round, state),
        ));
        continue;
      }

      int maxRoundDibutuhkan = 0;
      for (final h in act.hasil) {
        final res = state.getResourceById(h.resourceId);
        if (res == null || h.jumlahPerRound <= 0) continue;
        final kekurangan = max(0, res.target - res.stok);
        final roundButuh = (kekurangan / h.jumlahPerRound).ceil();
        if (roundButuh > maxRoundDibutuhkan) maxRoundDibutuhkan = roundButuh;
      }

      int roundPerHari = (maxRoundDibutuhkan / sisaHariV).ceil();
      final roundMaxEnergi = energiSisa ~/ act.energiPerRound;
      roundPerHari = min(roundPerHari, roundMaxEnergi);
      if (act.maxRoundPerHari != null) {
        roundPerHari = min(roundPerHari, act.maxRoundPerHari!);
      }
      roundPerHari = max(0, roundPerHari);

      final energi = roundPerHari * act.energiPerRound;
      energiSisa -= energi;

      items.add(PlanResultItem(
        activity: act, round: roundPerHari, energi: energi,
        hasilText: _formatHasil(act, roundPerHari, state),
      ));
    }

    // ── Cek peringatan per RESOURCE (sama seperti All-In) ──────────────────
    final sortedResources = state.resources;

    for (final res in sortedResources) {
      final kekurangan = max(0, res.target - res.stok);
      if (kekurangan <= 0) continue;

      int produksiPerHari = 0;
      for (final item in items) {
        for (final h in item.activity.hasil) {
          if (h.resourceId == res.id) {
            produksiPerHari += h.jumlahPerRound * item.round;
          }
        }
      }

      if (produksiPerHari <= 0) {
        peringatan.add('${res.nama}: alokasi energi tidak cukup');
        continue;
      }

      final hariButuh = (kekurangan / produksiPerHari).ceil();
      if (hariButuh > sisaHari) {
        peringatan.add('${res.nama}: butuh ±$hariButuh hari lagi (dapat $produksiPerHari/hari), tapi sisa patch hanya $sisaHari hari.');
      }
    }
  } else {
    // ── MODE ALL-IN ────────────────────────────────────────────────────────
    for (final act in sortedActivities) {
      if (act.isGratis) {
        final round = act.maxRoundPerHari ?? 1;
        items.add(PlanResultItem(
          activity: act, round: round, energi: 0,
          hasilText: _formatHasil(act, round, state),
        ));
        continue;
      }

      int maxRoundDibutuhkan = 0;
      for (final h in act.hasil) {
        final res = state.getResourceById(h.resourceId);
        if (res == null || h.jumlahPerRound <= 0) continue;
        final kekurangan = max(0, res.target - res.stok);
        final roundButuh = (kekurangan / h.jumlahPerRound).ceil();
        if (roundButuh > maxRoundDibutuhkan) maxRoundDibutuhkan = roundButuh;
      }

      int roundPerHari = energiSisa ~/ act.energiPerRound;
      roundPerHari = min(roundPerHari, maxRoundDibutuhkan);
      if (act.maxRoundPerHari != null) {
        roundPerHari = min(roundPerHari, act.maxRoundPerHari!);
      }
      roundPerHari = max(0, roundPerHari);

      final energi = roundPerHari * act.energiPerRound;
      energiSisa -= energi;

      items.add(PlanResultItem(
        activity: act, round: roundPerHari, energi: energi,
        hasilText: _formatHasil(act, roundPerHari, state),
      ));
    }

    // ── Cek peringatan per RESOURCE (bukan per activity) ───────────────────
    final sortedResources = state.resources;

    for (final res in sortedResources) {
      final kekurangan = max(0, res.target - res.stok);
      if (kekurangan <= 0) continue;

      // Total produksi resource ini per hari dari SEMUA activity yang menghasilkannya
      // (gratis dihitung penuh, energi dihitung dari round yang sudah dialokasikan di plan)
      int produksiPerHari = 0;
      for (final item in items) {
        for (final h in item.activity.hasil) {
          if (h.resourceId == res.id) {
            produksiPerHari += h.jumlahPerRound * item.round;
          }
        }
      }

      if (produksiPerHari <= 0) {
        peringatan.add('${res.nama}: alokasi energi tidak cukup.');
        continue;
      }

      final hariButuh = (kekurangan / produksiPerHari).ceil();
      if (hariButuh > sisaHari) {
        peringatan.add('${res.nama}: butuh ±$hariButuh hari lagi (dapat $produksiPerHari/hari), tapi sisa patch hanya $sisaHari hari.');
      }
    }
  }

  return DailyPlanResult(items: items, energiSisa: energiSisa, peringatan: peringatan);
}
