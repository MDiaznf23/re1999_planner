import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/character_upgrade_state_model.dart';
import '../models/stage_task_model.dart';
import '../models/material_target_model.dart';
import '../services/storage_service_character.dart';
import '../logic/game_day.dart';
import '../logic/character_daily_plan.dart';
import '../logic/character_plan_parser.dart';

class CharacterUpgradeProvider extends ChangeNotifier {
  CharacterUpgradeState? state;
  bool loading = true;
  String statusMsg = '';
  CharacterDailyPlanResult? planResult;
  CharacterDailyPlanResult? _planSnapshot;
  bool _snapshotSaved = false;

  CharacterDailyPlanResult? get displayPlan {
    final plan = _planSnapshot ?? planResult;
    if (plan == null) return null;

    // Item yang sudah dicentang hari ini TETAP ditampilkan (grayed/selesai)
    final itemsAktif = plan.items
        .where((it) =>
            !it.stage.selesai || state!.stageSelesaiHariIni.contains(it.stage.id))
        .toList();
    if (itemsAktif.length == plan.items.length) return plan;

    return CharacterDailyPlanResult(
      items: itemsAktif,
      energiSisa: plan.energiSisa,
      adaWilderness: plan.adaWilderness,
    );
  }

  Future<void> init(int energiPerHari, int resetHour) async {
    state = await StorageServiceCharacter.loadState();
    state ??= StorageServiceCharacter.createDefaultState(energiPerHari, resetHour);
    await _checkRollover();
    await _loadSnapshot();
    _recalcPlan();
    loading = false;
    notifyListeners();
  }

  void _recalcPlan() {
    if (state != null) {

      _pruneOrphanStageTasks();

      _pruneOrphanMaterialTargets();

      _autoCompleteStagesIfReady();
      planResult = hitungCharacterDailyPlan(state!);
      if (!_snapshotSaved) {
        _planSnapshot = planResult;
      }
    }
  }

  void _pruneOrphanStageTasks() {
    final namaKarakterAktif = state!.characters.map((c) => c.characterNama).toSet();
    final orphanIds = state!.stageTasks
        .where((s) => !namaKarakterAktif.contains(s.characterNama))
        .map((s) => s.id)
        .toSet();
    if (orphanIds.isEmpty) return;

    state!.stageTasks.removeWhere((s) => orphanIds.contains(s.id));
    state!.stageSelesaiHariIni.removeWhere((id) => orphanIds.contains(id));
    state!.runsHariIniPerStage.removeWhere((id, _) => orphanIds.contains(id));
    state!.autoCompleteSnapshot.removeWhere((id, _) => orphanIds.contains(id));
  }

  void _pruneOrphanMaterialTargets() {
    final materialDipakaiStage = <String>{
      for (final s in state!.stageTasks)
        if (s.hasProgressBar)
          for (final m in s.materialsInfo) m.nama,
    };
    state!.materialTargets.removeWhere((mt) {
      final dipakaiStage = materialDipakaiStage.contains(mt.nama);
      final dipakaiWilderness = (mt.nama == 'Dust' && state!.dailyDust > 0) ||
          (mt.nama == 'Sharpodonty' && state!.dailySharpodonty > 0);
      return !dipakaiStage && !dipakaiWilderness;
    });
  }

  Future<void> _invalidateSnapshot() async {
    _snapshotSaved = false;
    _planSnapshot = null;
    await StorageServiceCharacter.deleteSnapshot();
  }

  Future<void> _persistSnapshot() async {
    if (_planSnapshot == null) return;
    final raw = jsonEncode(_planSnapshot!.items.map((i) => {
          'stage_id': i.stage.id,
          'runs_hari_ini': i.runsHariIni,
          'energi_dipakai': i.energiDipakai,
        }).toList());
    await StorageServiceCharacter.saveSnapshot(raw);
    _snapshotSaved = true;
  }

  Future<void> _loadSnapshot() async {
    final raw = await StorageServiceCharacter.loadSnapshot();
    if (raw == null || state == null) return;
    final decoded = jsonDecode(raw) as List;

    final items = <StageRunHariIni>[];
    for (final i in decoded) {
      StageTask? stage;
      for (final s in state!.stageTasks) {
        if (s.id == i['stage_id']) {
          stage = s;
          break;
        }
      }
      if (stage == null) continue;
      items.add(StageRunHariIni(
        stage: stage,
        runsHariIni: i['runs_hari_ini'],
        energiDipakai: i['energi_dipakai'],
      ));
    }

    final energiTerpakai = items.fold<int>(0, (sum, it) => sum + it.energiDipakai);
    final energiSisaSnapshot = state!.energiPerHari - energiTerpakai;

    _planSnapshot = CharacterDailyPlanResult(
      items: items,
      energiSisa: energiSisaSnapshot,
      adaWilderness: state!.dailyDust > 0 || state!.dailySharpodonty > 0,
    );
    _snapshotSaved = true;
  }

  Future<void> _persist() async => StorageServiceCharacter.saveState(state!);

  // ── Rollover ──────────────────────────────────────────────────────────────

  Future<void> _checkRollover() async {
    final gameToday = formatGameDate(getGameDay(state!.gameDayResetHour));
    if (state!.hariIniGameDate == gameToday) return;

    if (state!.stageSelesaiHariIni.isNotEmpty || state!.wildernessSelesaiHariIni) {
      state!.history.insert(0, CharacterUpgradeHistoryEntry(
        tanggal: state!.hariIniGameDate,
        stageSelesai: List.from(state!.stageSelesaiHariIni),
      ));
    }

    state!.stageSelesaiHariIni = [];
    state!.runsHariIniPerStage = {};
    state!.wildernessSelesaiHariIni = false;
    state!.hariIniGameDate = gameToday;
    await _invalidateSnapshot();
    setStatus('🌅 Hari game baru dimulai!');
  }

  Future<void> checkDayRollover() async {
    if (state == null) return;
    final before = state!.hariIniGameDate;
    await _checkRollover();
    if (before != state!.hariIniGameDate) {
      await _persist();
      _recalcPlan();
      notifyListeners();
    }
  }

  Future<void> tandaiSemuaSelesai() async {

    final items = List<StageRunHariIni>.from(planResult?.items ?? const <StageRunHariIni>[]);

    if (!_snapshotSaved) await _persistSnapshot();

    for (final item in items) {
      if (!state!.stageSelesaiHariIni.contains(item.stage.id)) {
        state!.stageSelesaiHariIni.add(item.stage.id);
        state!.runsHariIniPerStage[item.stage.id] = item.runsHariIni;
        item.stage.runsSelesai += item.runsHariIni;

        if (item.stage.hasProgressBar) {
          for (final m in item.stage.materialsInfo) {
            final target = state!.getMaterialTarget(m.nama);

            if (target != null) {
              target.stok += (m.jumlahPerRun * item.runsHariIni).round();
            }
          }
        }
      }
    }

    if (planResult != null && planResult!.adaWilderness &&
        !state!.wildernessSelesaiHariIni) {
      state!.wildernessSelesaiHariIni = true;
      final dust = state!.getMaterialTarget('Dust');
      final sharp = state!.getMaterialTarget('Sharpodonty');
      if (dust != null) dust.stok += state!.dailyDust;
      if (sharp != null) sharp.stok += state!.dailySharpodonty;
    }

    await _persist();
    _recalcPlan();
    setStatus('✅ Semua task selesai!');
    notifyListeners();
  }

  // ── Toggle Stage ──────────────────────────────────────────────────────────

  Future<void> toggleStage(String stageId, bool checked, int runsHariIni) async {
    final stage = state!.stageTasks.firstWhere((s) => s.id == stageId);

    if (checked) {
      if (!state!.stageSelesaiHariIni.contains(stageId)) {
        state!.stageSelesaiHariIni.add(stageId);
        if (!_snapshotSaved) await _persistSnapshot();
        state!.runsHariIniPerStage[stageId] = runsHariIni;
        stage.runsSelesai += runsHariIni;

        if (stage.hasProgressBar) {
          for (final m in stage.materialsInfo) {
            final target = state!.getMaterialTarget(m.nama);
            if (target != null) {
              target.stok += (m.jumlahPerRun * runsHariIni).round();
            }
          }
        }
        setStatus('✅ ${stage.namaStage} — $runsHariIni run selesai');
      }
    } else {
      final savedRuns = state!.runsHariIniPerStage[stageId] ?? runsHariIni;
      state!.stageSelesaiHariIni.remove(stageId);
      state!.runsHariIniPerStage.remove(stageId);
      stage.runsSelesai -= savedRuns;
      if (stage.runsSelesai < 0) stage.runsSelesai = 0;

      if (stage.hasProgressBar) {
        for (final m in stage.materialsInfo) {
          final target = state!.getMaterialTarget(m.nama);
          if (target != null) {
            target.stok -= (m.jumlahPerRun * savedRuns).round();
            if (target.stok < 0) target.stok = 0;
          }
        }
      }
      setStatus('↩ ${stage.namaStage} dibatalkan.');
    }

    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  // ── Wilderness ────────────────────────────────────────────────────────────

  Future<void> toggleWilderness(bool checked) async {
    state!.wildernessSelesaiHariIni = checked;

    if (checked) {
      final dust = state!.getMaterialTarget('Dust');
      final sharp = state!.getMaterialTarget('Sharpodonty');
      if (dust != null) dust.stok += state!.dailyDust;
      if (sharp != null) sharp.stok += state!.dailySharpodonty;
      setStatus('✅ Wilderness collected.');
    } else {
      final dust = state!.getMaterialTarget('Dust');
      final sharp = state!.getMaterialTarget('Sharpodonty');
      if (dust != null) dust.stok -= state!.dailyDust;
      if (sharp != null) sharp.stok -= state!.dailySharpodonty;
      setStatus('↩ Wilderness dibatalkan.');
    }

    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  // ── Import Karakter ───────────────────────────────────────────────────────

  Future<bool> importCharacterFromFile() async {
    if (state!.characters.length >= 4) {
      setStatus('❌ Maksimal 4 karakter aktif.');
      return false;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final characterNama = (json['character'] ?? json['arcanist'] ?? 'Unknown').toString();
      final sudahAda = state!.characters.any((c) =>
          c.characterNama.trim().toLowerCase() == characterNama.trim().toLowerCase());
      if (sudahAda) {
        setStatus('❌ Karakter "$characterNama" sudah diimport.');
        notifyListeners();
        return false;
      }

      final startPrioritas = state!.stageTasks.isEmpty
          ? 1
          : state!.stageTasks.map((s) => s.prioritas).reduce((a, b) => a > b ? a : b) + 1;

      final data = parseCharacterJson(json, startPrioritas);
      mergeCharacterToState(state!, data);

      await _invalidateSnapshot();
      await _persist();
      _recalcPlan();
      setStatus('✅ ${data.plan.characterNama} berhasil diimport.');
      notifyListeners();
      return true;
    } catch (e) {
      setStatus('❌ Gagal import: format tidak valid.');
      notifyListeners();
      return false;
    }
  }

  // ── Hapus Karakter ────────────────────────────────────────────────────────

  Future<void> removeCharacter(String characterId) async {
    final char = state!.characters.firstWhere((c) => c.id == characterId);
    final removedStageIds =
        state!.stageTasks.where((s) => s.characterNama == char.characterNama).map((s) => s.id).toSet();

    state!.characters.removeWhere((c) => c.id == characterId);
    state!.stageTasks.removeWhere((s) => s.characterNama == char.characterNama);
    state!.stageSelesaiHariIni.removeWhere((id) => removedStageIds.contains(id));

    state!.runsHariIniPerStage.removeWhere((id, _) => removedStageIds.contains(id));

    final materialMasihDipakaiStage = <String>{
      for (final s in state!.stageTasks)
        if (s.hasProgressBar)
          for (final m in s.materialsInfo) m.nama,
    };

    int dustBaru = 0;
    int sharpBaru = 0;
    for (final c in state!.characters) {
      if (c.dailyDust > dustBaru) dustBaru = c.dailyDust;
      if (c.dailySharpodonty > sharpBaru) sharpBaru = c.dailySharpodonty;
    }

    if (dustBaru != state!.dailyDust || sharpBaru != state!.dailySharpodonty) {
      state!.wildernessSelesaiHariIni = false;
    }
    state!.dailyDust = dustBaru;
    state!.dailySharpodonty = sharpBaru;

    for (final entry in char.materialTargetContrib.entries) {
      final namaMaterial = entry.key;
      final target = state!.getMaterialTarget(namaMaterial);
      if (target == null) continue;

      final masihDipakai = materialMasihDipakaiStage.contains(namaMaterial) ||
          (namaMaterial == 'Dust' && state!.dailyDust > 0) ||
          (namaMaterial == 'Sharpodonty' && state!.dailySharpodonty > 0);

      if (!masihDipakai) {
        state!.materialTargets.remove(target);
      } else {
        target.target -= entry.value;
        if (target.target < 0) target.target = 0;
      }
    }

    await _invalidateSnapshot();

    await _persist();
    _recalcPlan();
    setStatus('🗑 ${char.characterNama} dihapus.');
    notifyListeners();
  }

  // ── Edit Stok Material ────────────────────────────────────────────────────

  Future<void> editStokMaterial(String nama, int stokBaru) async {
    final target = state!.getMaterialTarget(nama);
    if (target != null) {
      target.stok = stokBaru;
    }
    await _persist();
    _recalcPlan();
    notifyListeners();
  }

  // ── Bonus ─────────────────────────────────────────────────────────────────

  Future<void> applyBonus(Map<String, int> stokFinal) async {
    for (final entry in stokFinal.entries) {
      final target = state!.getMaterialTarget(entry.key);
      if (target != null) target.stok = entry.value;
    }
    await _persist();
    _recalcPlan();
    notifyListeners();
    setStatus('✅ Bonus disimpan.');
  }

  void _autoCompleteStagesIfReady() {
    for (final stage in state!.stageTasks) {
      if (!stage.hasProgressBar) continue;
      if (stage.materialsInfo.isEmpty) continue;

      final semuaMaterialTercapai = stage.materialsInfo.every((m) {
        final target = state!.getMaterialTarget(m.nama);
        return target != null && target.stok >= target.target;
      });

      if (semuaMaterialTercapai) {
        if (!stage.selesai) {
          state!.autoCompleteSnapshot[stage.id] = stage.runsSelesai;
          stage.runsSelesai = stage.totalRuns;
        }
      } else {
        final runsSebelumAuto = state!.autoCompleteSnapshot[stage.id];
        if (runsSebelumAuto != null && stage.runsSelesai >= stage.totalRuns) {
          stage.runsSelesai = runsSebelumAuto;
          state!.autoCompleteSnapshot.remove(stage.id);
        }
      }
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetHariIni() async {
    for (final stageId in List.from(state!.stageSelesaiHariIni)) {
      final stage = state!.stageTasks.firstWhere((s) => s.id == stageId);
      final savedRuns = state!.runsHariIniPerStage[stageId] ?? 0;

      stage.runsSelesai -= savedRuns;
      if (stage.runsSelesai < 0) stage.runsSelesai = 0;

      if (stage.hasProgressBar) {
        for (final m in stage.materialsInfo) {
          final target = state!.getMaterialTarget(m.nama);
          if (target != null) {
            target.stok -= (m.jumlahPerRun * savedRuns).round();
            if (target.stok < 0) target.stok = 0;
          }
        }
      }
    }

    if (state!.wildernessSelesaiHariIni) {
      final dust = state!.getMaterialTarget('Dust');
      final sharp = state!.getMaterialTarget('Sharpodonty');
      if (dust != null) dust.stok -= state!.dailyDust;
      if (sharp != null) sharp.stok -= state!.dailySharpodonty;
    }

    state!.stageSelesaiHariIni = [];
    state!.runsHariIniPerStage = {};
    await _invalidateSnapshot();
    state!.wildernessSelesaiHariIni = false;
    await _persist();
    _recalcPlan();
    setStatus('🔄 Hari ini direset.');
    notifyListeners();
  }

  Future<void> resetAll() async {
    for (final s in state!.stageTasks) s.runsSelesai = 0;
    for (final m in state!.materialTargets) m.stok = 0;
    state!.stageSelesaiHariIni = [];
    
    state!.runsHariIniPerStage = {};
    
    state!.autoCompleteSnapshot = {};
    state!.wildernessSelesaiHariIni = false;
    state!.history = [];
    await _invalidateSnapshot();
    await _persist();
    _recalcPlan();
    setStatus('🔄 Semua direset.');
    notifyListeners();
  }

  // ── Update Config ─────────────────────────────────────────────────────────

  Future<void> updateEnergi(int energiPerHari) async {
    state!.energiPerHari = energiPerHari;
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

  // PENTING: harus pakai `displayPlan` (bukan `planResult` mentah), karena
  // itu yang benar-benar dirender di layar. planResult dihitung ulang dari
  // nol tiap kali _recalcPlan() jalan (misal tiap toggle), jadi daftar
  // itemnya bisa berubah/menyusut begitu ada stage yang baru saja selesai.
  // Kalau semuaSelesai dicek terhadap planResult yang sudah berubah itu,
  // hasilnya bisa tidak pernah cocok dengan apa yang user lihat & centang.
  bool get semuaSelesai {
    final plan = displayPlan;
    if (plan == null) return false;
    if (plan.adaWilderness && !state!.wildernessSelesaiHariIni) return false;
    if (plan.items.isEmpty) return plan.adaWilderness && state!.wildernessSelesaiHariIni;
    return plan.items.every((i) => state!.stageSelesaiHariIni.contains(i.stage.id));
  }

  bool get adaTaskHariIni {
    final plan = displayPlan;
    return plan != null && plan.items.isNotEmpty;
  }
}
