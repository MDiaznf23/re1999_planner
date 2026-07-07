import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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

  // ── Snapshot plan (freeze saat task pertama dicentang) ─────────────────────
  List<Map<String, dynamic>>? _planSnapshotRaw;

  Future<void> init() async {
    state = await StorageServiceV2.loadState();
    if (state == null) {
      state = StorageServiceV2.createDefaultState();
      await StorageServiceV2.saveState(state!);
    }
    await _loadSnapshot();
    await _checkRollover();
    _recalcPlan();
    loading = false;
    notifyListeners();
  }

  void _recalcPlan() {
    if (state == null) return;
    if (_planSnapshotRaw != null) {
      // Plan sudah di-freeze, jangan hitung ulang dari stok terbaru.
      planResult = _buildPlanFromSnapshot();
    } else {
      planResult = hitungDailyPlan(state!);
    }
  }

  DailyPlanResult _buildPlanFromSnapshot() {
    final items = <PlanResultItem>[];
    int energiSisa = 0;

    for (final snap in _planSnapshotRaw!) {
      if (snap['key'] == '__meta__') {
        energiSisa = snap['energiSisa'] as int? ?? 0;
        continue;
      }
      final activity = state!.getActivityById(snap['key'] as String);
      if (activity == null) continue; // activity mungkin sudah dihapus
      items.add(PlanResultItem(
        activity: activity,
        round: snap['round'] as int,
        energi: snap['energi'] as int,
        hasilText: snap['hasil'] as String,
      ));
    }

    final peringatan = hitungPeringatanUntukSnapshot(state!, items);
    return DailyPlanResult(items: items, energiSisa: energiSisa, peringatan: peringatan);
  }

  List<Map<String, dynamic>> _snapshotFromPlan(DailyPlanResult p) {
    return [
      ...p.items.map((i) => {
            'key': i.activity.id,
            'round': i.round,
            'energi': i.energi,
            'hasil': i.hasilText,
          }),
      {
        'key': '__meta__',
        'energiSisa': p.energiSisa,
        'peringatan': p.peringatan,
      },
    ];
  }

  DailyPlanResult? get displayPlan => planResult;

  Future<void> _persist() async {
    await StorageServiceV2.saveState(state!);
  }

  // ── Snapshot persistence ─────────────────────────────────────────────────

  Future<void> _loadSnapshot() async {
    _planSnapshotRaw = await StorageServiceV2.loadSnapshot();
  }

  Future<void> _saveSnapshot() async {
    if (_planSnapshotRaw != null) {
      await StorageServiceV2.saveSnapshot(_planSnapshotRaw!);
    }
  }

  Future<void> _clearSnapshot() async {
    _planSnapshotRaw = null;
    await StorageServiceV2.deleteSnapshot();
  }

  // ── Rollover ──────────────────────────────────────────────────────────────

  Future<void> _checkRollover() async {
    final gameToday = formatGameDate(getGameDay(state!.plannerConfig.gameDayResetHour));
    if (state!.hariIniGameDate != gameToday) {
      if (!state!.taskHariIniSudahSelesaiSemua && state!.activitySelesaiHariIni.isNotEmpty) {
        _commitToHistory();
      }
      state!.activitySelesaiHariIni = [];
      state!.roundHariIniPerActivity = {};
      state!.hariIniGameDate = gameToday;
      state!.stokAwalHari = {for (final r in state!.resources) r.id: r.stok};
      state!.taskHariIniSudahSelesaiSemua = false;
      await _clearSnapshot(); // hari baru → plan lama nggak relevan lagi
    }
  }

  Future<void> checkDayRollover() async {
    if (state == null) return;
    final before = state!.hariIniGameDate;
    await _checkRollover();
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
    state!.resources.add(Resource(id: _uuid.v4(), nama: nama, target: target, stok: 0));
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

  // ── Reorder Activity ──────────────────────────────────────────────────────

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

    // Freeze plan begitu task PERTAMA dicentang hari ini
    if (checked && _planSnapshotRaw == null && planResult != null) {
      _planSnapshotRaw = _snapshotFromPlan(planResult!);
      await _saveSnapshot();
    }

    if (checked) {
      if (!state!.activitySelesaiHariIni.contains(activityId)) {
        state!.activitySelesaiHariIni.add(activityId);
        for (final h in act.hasil) {
          final res = state!.getResourceById(h.resourceId);
          if (res != null) res.stok += h.jumlahPerRound * round;
        }

        state!.roundHariIniPerActivity[activityId] = round;
        setStatus('✅ ${act.nama} — ${planItem?.hasilText}');
      }
    } else {
      state!.activitySelesaiHariIni.remove(activityId);
      for (final h in act.hasil) {
        final res = state!.getResourceById(h.resourceId);
        if (res != null) res.stok -= h.jumlahPerRound * round;
      }
      state!.roundHariIniPerActivity.remove(activityId);
      setStatus('↩ ${act.nama} dibatalkan.');
    }

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

    // Freeze plan kalau belum di-freeze
    if (_planSnapshotRaw == null && planResult != null) {
      _planSnapshotRaw = _snapshotFromPlan(planResult!);
      await _saveSnapshot();
    }

    for (final item in eligible) {
      if (!state!.activitySelesaiHariIni.contains(item.activity.id)) {
        state!.activitySelesaiHariIni.add(item.activity.id);
        for (final h in item.activity.hasil) {
          final res = state!.getResourceById(h.resourceId);
          if (res != null) res.stok += h.jumlahPerRound * item.round;
        }
        state!.roundHariIniPerActivity[item.activity.id] = item.round;
      }
    }
    state!.taskHariIniSudahSelesaiSemua = true;
    _commitToHistory();
    await _persist();
    setStatus('✅ Semua task selesai! Masuk ke history.');
    notifyListeners();
  }

  // ── Bonus ─────────────────────────────────────────────────────────────────

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
    for (final activityId in state!.activitySelesaiHariIni) {
      final act = state!.getActivityById(activityId);
      if (act == null) continue;
      final round = state!.roundHariIniPerActivity[activityId] ?? 0;
      if (round <= 0) continue;
      for (final h in act.hasil) {
        final res = state!.getResourceById(h.resourceId);
        if (res != null) {
          res.stok -= h.jumlahPerRound * round;
          if (res.stok < 0) res.stok = 0;
        }
      }
    }

    state!.activitySelesaiHariIni = [];
    state!.roundHariIniPerActivity = {};
    state!.taskHariIniSudahSelesaiSemua = false;
    await _clearSnapshot(); // reset → plan boleh dihitung ulang lagi
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
    state!.roundHariIniPerActivity = {};
    state!.taskHariIniSudahSelesaiSemua = false;
    state!.stokAwalHari = {for (final r in state!.resources) r.id: 0};
    await _clearSnapshot();
    await _persist();
    _recalcPlan();
    setStatus('🔄 Semua direset.');
    notifyListeners();
  }

  // ── Export / Import Config ───────────────────────────────────────────────

  Map<String, dynamic> exportConfigJson() {
    return {
      'resources': state!.resources.map((r) => {'id': r.id, 'nama': r.nama, 'target': r.target}).toList(),
      'activities': state!.activities.map((a) => a.toJson()).toList(),
      'planner_config': state!.plannerConfig.toJson(),
    };
  }

  /// Mengembalikan path file hasil export, atau null kalau user
  /// membatalkan dialog simpan.
  Future<String?> exportToFile() async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(exportConfigJson())));

    // Pakai dialog "Simpan Sebagai" native (Storage Access Framework di
    // Android) supaya user bisa pilih sendiri lokasi yang bisa dia akses
    // (misal Downloads), bukan otomatis ke folder privat app yang cuma
    // bisa dibuka kalau HP di-root.
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan config export',
      fileName: 'r1999_config_export.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    return savedPath;
  }

  Future<bool> pickAndImportFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return false;
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return _applyImport(json);
  }

  bool _applyImport(Map<String, dynamic> json) {
    try {
      final newResources = (json['resources'] as List).map((r) => Resource(
        id: r['id'], nama: r['nama'], target: r['target'] ?? 0, stok: 0,
      )).toList();
      final newActivities = (json['activities'] as List).map((a) => Activity.fromJson(a)).toList();

      state!.resources = newResources;
      state!.activities = newActivities;
      state!.plannerConfig = PlannerConfig.fromJson(json['planner_config']);
      state!.activitySelesaiHariIni = [];
      state!.roundHariIniPerActivity = {};
      state!.taskHariIniSudahSelesaiSemua = false;
      state!.stokAwalHari = {for (final r in newResources) r.id: 0};

      _clearSnapshot();
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
