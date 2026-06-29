import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_state_model.dart';
import '../models/resource_model.dart';
import '../models/activity_model.dart';
import '../models/history_model.dart';
import '../models/planner_config_model.dart';
import '../services/storage_service_v2.dart';
import '../logic/game_day.dart';
import '../logic/daily_plan_v2.dart';

class AppProviderV2 extends ChangeNotifier {
  AppState? state;
  bool loading = true;
  String statusMsg = '';
  DailyPlanResult? planResult;
  final _uuid = const Uuid();

  Future<void> init() async {
    state = await StorageServiceV2.loadState();
    if (state == null) {
      state = StorageServiceV2.createDefaultState();
      await StorageServiceV2.saveState(state!);
    }
    _checkRollover();
    _recalcPlan();
    loading = false;
    notifyListeners();
  }

  void _recalcPlan() {
    if (state != null) {
      planResult = hitungDailyPlan(state!);
    }
  }

  Future<void> _persist() async {
    await StorageServiceV2.saveState(state!);
  }

  // ── Rollover ──────────────────────────────────────────────────────────────

  void _checkRollover() {
    final gameToday = formatGameDate(getGameDay(state!.plannerConfig.gameDayResetHour));
    if (state!.hariIniGameDate != gameToday) {
      // Kalau task hari ini belum masuk history (belum centang semua), masukkan sekarang
      if (!state!.taskHariIniSudahSelesaiSemua && state!.activitySelesaiHariIni.isNotEmpty) {
        _commitToHistory();
      }
      state!.activitySelesaiHariIni = [];
      state!.hariIniGameDate = gameToday;
      state!.stokAwalHari = {for (final r in state!.resources) r.id: r.stok};
      state!.taskHariIniSudahSelesaiSemua = false;
    }
  }

  Future<void> checkDayRollover() async {
    if (state == null) return;
    final before = state!.hariIniGameDate;
    _checkRollover();
    if (before != state!.hariIniGameDate) {
      await _persist();
      _recalcPlan();
      setStatus('🌅 Hari game baru dimulai!');
      notifyListeners();
    }
  }

  void _commitToHistory() {
    final namaActivities = state!.activitySelesaiHariIni
        .map((id) => state!.getActivityById(id)?.nama ?? id)
        .toList();
    state!.history.insert(0, HistoryEntry(
      tanggal: state!.hariIniGameDate,
      activitySelesai: namaActivities,
      stokAkhir: {for (final r in state!.resources) r.id: r.stok},
    ));
  }

  // ── Resource CRUD ─────────────────────────────────────────────────────────

  Future<void> addResource(String nama, int target) async {
    state!.resources.add(Resource(
      id: _uuid.v4(), nama: nama, target: target, stok: 0,
    ));
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  Future<void> updateResource(String id, {String? nama, int? target}) async {
    final idx = state!.resources.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    state!.resources[idx] = state!.resources[idx].copyWith(nama: nama, target: target);
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  Future<void> deleteResource(String id) async {
    state!.resources.removeWhere((r) => r.id == id);
    // Hapus juga referensi di activity hasil
    for (final act in state!.activities) {
      act.hasil.removeWhere((h) => h.resourceId == id);
    }
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  // ── Activity CRUD ─────────────────────────────────────────────────────────

  Future<void> addActivity(String nama, int energiPerRound, List<ActivityResult> hasil, int prioritas, {int? maxRound}) async {
    state!.activities.add(Activity(
      id: _uuid.v4(), nama: nama, energiPerRound: energiPerRound,
      hasil: hasil, prioritas: prioritas, maxRoundPerHari: maxRound,
    ));
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  Future<void> updateActivity(String id, {String? nama, int? energiPerRound, List<ActivityResult>? hasil, int? prioritas, int? maxRound}) async {
    final idx = state!.activities.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final old = state!.activities[idx];
    state!.activities[idx] = Activity(
      id: old.id,
      nama: nama ?? old.nama,
      energiPerRound: energiPerRound ?? old.energiPerRound,
      hasil: hasil ?? old.hasil,
      prioritas: prioritas ?? old.prioritas,
      maxRoundPerHari: maxRound ?? old.maxRoundPerHari,
    );
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  // ── Reorder Activity (insert & shift) ────────────────────────────────────

  Future<void> setActivityPriority(String activityId, int newPriority) async {
    final activity = state!.getActivityById(activityId);
    if (activity == null) return;

    final oldPriority = activity.prioritas;
    if (oldPriority == newPriority) return;

    final sorted = List<Activity>.from(state!.activities)
      ..sort((a, b) => a.prioritas.compareTo(b.prioritas));

    sorted.removeWhere((a) => a.id == activityId);

    final clampedNew = newPriority.clamp(1, sorted.length + 1);
    sorted.insert(clampedNew - 1, activity);

    for (int i = 0; i < sorted.length; i++) {
      sorted[i].prioritas = i + 1;
    }

    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  Future<void> reorderActivityByDrag(int oldIndex, int newIndex) async {
    final sorted = List<Activity>.from(state!.activities)
      ..sort((a, b) => a.prioritas.compareTo(b.prioritas));

    if (newIndex > oldIndex) newIndex -= 1;
    final item = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, item);

    for (int i = 0; i < sorted.length; i++) {
      sorted[i].prioritas = i + 1;
    }

    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  Future<void> deleteActivity(String id) async {
    state!.activities.removeWhere((a) => a.id == id);
    state!.activitySelesaiHariIni.remove(id);
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  // ── Daily Task Actions ────────────────────────────────────────────────────

  Future<void> toggleActivity(String activityId, bool checked) async {
    if (state!.taskHariIniSudahSelesaiSemua) return;

    final act = state!.getActivityById(activityId);
    if (act == null) return;
    final planItem = planResult?.items.firstWhere(
      (i) => i.activity.id == activityId,
      orElse: () => PlanResultItem(activity: act, round: 0, energi: 0, hasilText: ''),
    );
    final round = planItem?.round ?? 0;

    if (checked) {
      if (!state!.activitySelesaiHariIni.contains(activityId)) {
        state!.activitySelesaiHariIni.add(activityId);
        for (final h in act.hasil) {
          final res = state!.getResourceById(h.resourceId);
          if (res != null) res.stok += h.jumlahPerRound * round;
        }
        setStatus('✅ ${act.nama} — ${planItem?.hasilText}');
      }
    } else {
      state!.activitySelesaiHariIni.remove(activityId);
      for (final h in act.hasil) {
        final res = state!.getResourceById(h.resourceId);
        if (res != null) res.stok -= h.jumlahPerRound * round;
      }
      setStatus('↩ ${act.nama} dibatalkan.');
    }

    // Cek apakah semua eligible activity sudah dicentang
    final eligibleIds = planResult?.items
        .where((i) => i.round > 0 || i.activity.isGratis)
        .map((i) => i.activity.id)
        .toSet() ?? {};
    if (eligibleIds.isNotEmpty && eligibleIds.every((id) => state!.activitySelesaiHariIni.contains(id))) {
      state!.taskHariIniSudahSelesaiSemua = true;
      _commitToHistory();
      setStatus('✅ Semua task selesai! Masuk ke history.');
    }

    await _persist();
    notifyListeners();
  }

  Future<void> tandaiSemuaSelesai() async {
    final eligible = planResult?.items.where((i) => i.round > 0 || i.activity.isGratis).toList() ?? [];
    for (final item in eligible) {
      if (!state!.activitySelesaiHariIni.contains(item.activity.id)) {
        state!.activitySelesaiHariIni.add(item.activity.id);
        for (final h in item.activity.hasil) {
          final res = state!.getResourceById(h.resourceId);
          if (res != null) res.stok += h.jumlahPerRound * item.round;
        }
      }
    }
    state!.taskHariIniSudahSelesaiSemua = true;
    _commitToHistory();
    await _persist();
    setStatus('✅ Semua task selesai! Masuk ke history.');
    notifyListeners();
  }

  // ── Bonus (hanya aktif kalau sudah selesai semua) ────────────────────────

  bool get canInputBonus => state!.taskHariIniSudahSelesaiSemua;

  Future<void> applyBonus(Map<String, int> stokFinal) async {
    if (!canInputBonus) return;
    for (final entry in stokFinal.entries) {
      final res = state!.getResourceById(entry.key);
      if (res != null) res.stok = entry.value;
    }
    await _persist();
    _recalcPlan();
    setStatus('✅ Stok bonus disimpan.');
    notifyListeners();
  }

  Future<void> editStokManual(Map<String, int> stokBaru) async {
    for (final entry in stokBaru.entries) {
      final res = state!.getResourceById(entry.key);
      if (res != null) res.stok = entry.value;
    }
    await _persist();
    _recalcPlan();
    setStatus('✅ Stok diedit manual.');
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetHariIni() async {
    // Kembalikan stok ke snapshot awal hari, uncentang semua
    for (final r in state!.resources) {
      r.stok = state!.stokAwalHari[r.id] ?? r.stok;
    }
    state!.activitySelesaiHariIni = [];
    state!.taskHariIniSudahSelesaiSemua = false;
    await _persist();
    _recalcPlan();
    setStatus('🔄 Hari ini direset.');
    notifyListeners();
  }

  Future<void> resetAll() async {
    for (final r in state!.resources) {
      r.stok = 0;
    }
    state!.history = [];
    state!.activitySelesaiHariIni = [];
    state!.taskHariIniSudahSelesaiSemua = false;
    state!.stokAwalHari = {for (final r in state!.resources) r.id: 0};
    await _persist();
    _recalcPlan();
    setStatus('🔄 Semua direset.');
    notifyListeners();
  }

  // ── Export / Import Config ───────────────────────────────────────────────

  Map<String, dynamic> exportConfigJson() {
    return {
      'resources': state!.resources.map((r) => {
        'id': r.id,
        'nama': r.nama,
        'target': r.target,
      }).toList(),
      'activities': state!.activities.map((a) => a.toJson()).toList(),
      'planner_config': state!.plannerConfig.toJson(),
    };
  }

  Future<String> exportToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/r1999_config_export.json');
    await file.writeAsString(jsonEncode(exportConfigJson()));
    return file.path;
  }

  Future<bool> pickAndImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    return _applyImport(json);
  }

  bool _applyImport(Map<String, dynamic> json) {
    try {
      final newResources = (json['resources'] as List).map((r) => Resource(
        id: r['id'],
        nama: r['nama'],
        target: r['target'] ?? 0,
        stok: 0, // selalu reset 0
      )).toList();

      final newActivities = (json['activities'] as List).map((a) => Activity.fromJson(a)).toList();

      state!.resources = newResources;
      state!.activities = newActivities;
      state!.plannerConfig = PlannerConfig.fromJson(json['planner_config']);
      state!.activitySelesaiHariIni = [];
      state!.taskHariIniSudahSelesaiSemua = false;
      state!.stokAwalHari = {for (final r in newResources) r.id: 0};

      _persist();
      _recalcPlan();
      setStatus('✅ Config berhasil di-import.');
      notifyListeners();
      return true;
    } catch (e) {
      setStatus('❌ Gagal import: format tidak valid.');
      notifyListeners();
      return false;
    }
  }

  // ── Mode Planner & Config ────────────────────────────────────────────────

  Future<void> updatePlannerConfig(int? energiPerHari, int? resetHour, String? tanggalMulai, String? tanggalAkhir) async {
    if (energiPerHari != null) state!.plannerConfig.energiPerHari = energiPerHari;
    if (resetHour != null) state!.plannerConfig.gameDayResetHour = resetHour;
    if (tanggalMulai != null) state!.plannerConfig.patch.tanggalMulai = tanggalMulai;
    if (tanggalAkhir != null) state!.plannerConfig.patch.tanggalAkhir = tanggalAkhir;
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  Future<void> togglePlannerMode() async {
    state!.plannerConfig.mode = state!.plannerConfig.mode == PlannerMode.rata
        ? PlannerMode.allIn
        : PlannerMode.rata;
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  void setStatus(String msg) {
    statusMsg = msg;
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      statusMsg = '';
      notifyListeners();
    });
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  int get sisaHari => state == null
      ? 0
      : hitungSisaHari(state!.plannerConfig.patch.tanggalAkhir, state!.plannerConfig.gameDayResetHour);
}
