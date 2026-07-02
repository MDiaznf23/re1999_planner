import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_upgrade_provider.dart';
import '../providers/app_provider_v2.dart';
import '../models/stage_task_model.dart';
import '../widgets/home_screen_colors.dart';
import 'character_history_screen.dart';
import 'farming_progress_screen.dart';

class CharacterUpgradeScreen extends StatefulWidget {
  const CharacterUpgradeScreen({super.key});
  @override
  State<CharacterUpgradeScreen> createState() => _CharacterUpgradeScreenState();
}

class _CharacterUpgradeScreenState extends State<CharacterUpgradeScreen> {
  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 60));
      if (!mounted) return false;
      await context.read<CharacterUpgradeProvider>().checkDayRollover();
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CharacterUpgradeProvider>();

    if (prov.loading) {
      return const Scaffold(
        backgroundColor: kBG,
        body: Center(child: CircularProgressIndicator(color: kAccent)),
      );
    }

    final state = prov.state!;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: kBG,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: kBG3,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHARACTER UPGRADE PLANNER',
                      style: TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '⚡ ${state.energiPerHari}/hari  '
                    '👤 ${state.characters.length}/4 karakter aktif',
                    style: const TextStyle(color: kSub, fontSize: 11),
                  ),
                ],
              ),
            ),

            // ── Toolbar ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: kBG2,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _btn(context, 'Import Karakter', () => _importKarakter(context)),
                    _btn(context, 'Karakter', () => _showKarakterDialog(context)),
                    _btn(context, 'History', () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CharacterHistoryScreen()))),
                    _btn(context, 'Farming', () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FarmingProgressScreen()))),
                    _btn(context, 'Config', () => _showConfigDialog(context)),
                    _btn(context, 'Reset All', () => _confirmReset(context, true)),
                  ],
                ),
              ),
            ),

            // ── Main Area ────────────────────────────────────────────────
            Expanded(
              child: state.characters.isEmpty
                  ? _buildEmptyView()
                  : isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 280, child: _buildMaterialPanel(context)),
                            Expanded(child: _buildTaskPanel(context)),
                          ],
                        )
                      : DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              const TabBar(
                                indicatorColor: kAccent,
                                labelColor: kAccent,
                                unselectedLabelColor: kSub,
                                tabs: [Tab(text: 'Material'), Tab(text: 'Tasks')],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildMaterialPanel(context),
                                    _buildTaskPanel(context),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),

            if (prov.statusMsg.isNotEmpty)
              Container(
                width: double.infinity,
                color: kBG3,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Text(prov.statusMsg, style: const TextStyle(color: kSub, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty View ─────────────────────────────────────────────────────────────

  Widget _buildEmptyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚔️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Belum ada karakter aktif.',
                style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Tap "➕ Import Karakter" untuk mulai.',
                style: TextStyle(color: kSub, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Material Panel ─────────────────────────────────────────────────────────

  Widget _buildMaterialPanel(BuildContext context) {
    final prov = context.watch<CharacterUpgradeProvider>();
    final targets = prov.state!.materialTargets;

    return Container(
      color: kBG2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MATERIAL PROGRESS',
                    style: TextStyle(color: kAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _showEditStokDialog(context),
                  style: TextButton.styleFrom(
                    backgroundColor: kBG3, foregroundColor: kText,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final t in targets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(t.nama,
                                style: const TextStyle(color: kText, fontSize: 11))),
                            Text('${t.stok}/${t.target}',
                                style: TextStyle(
                                  color: t.stok >= t.target ? kGreen
                                      : t.stok >= t.target * 0.5 ? kYellow : kRed,
                                  fontSize: 11, fontFamily: 'Courier',
                                )),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: t.target > 0
                                ? (t.stok / t.target).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 5,
                            backgroundColor: kBG,
                            valueColor: AlwaysStoppedAnimation(
                              t.stok >= t.target ? kGreen
                                  : t.stok >= t.target * 0.5 ? kYellow : kRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Task Panel ─────────────────────────────────────────────────────────────

  Widget _buildTaskPanel(BuildContext context) {
    final prov = context.watch<CharacterUpgradeProvider>();
    final state = prov.state!;
    final plan = prov.displayPlan;
    if (plan == null) return const SizedBox();

    final semua = prov.semuaSelesai;

    return Container(
      color: kBG2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text('DAILY TASKS',
                style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),

          // Wilderness (hilang begitu sudah dicentang, sama seperti task lain)
          if (plan.adaWilderness && !state.wildernessSelesaiHariIni)
            _buildWildernessRow(context),

          // Task list
          Expanded(
            child: semua
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✅', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 8),
                          Text('Semua task hari ini selesai!',
                              style: TextStyle(color: kGreen, fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: plan.items.length,
                    itemBuilder: (context, i) {
                      final item = plan.items[i];
                      final isDone = state.stageSelesaiHariIni.contains(item.stage.id);
                      final kategoriLabel = item.stage.kategori == StageKategori.resource
                          ? 'RESOURCE'
                          : item.stage.kategori == StageKategori.insight
                              ? 'INSIGHT'
                              : 'FARMING';
                      final kategoriColor = item.stage.kategori == StageKategori.resource
                          ? kRed
                          : item.stage.kategori == StageKategori.insight
                              ? kYellow
                              : kSub;

                      return Container(
                        color: isDone ? kBG : kBG2,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: kategoriColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(kategoriLabel,
                                            style: TextStyle(color: kategoriColor, fontSize: 9)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(item.stage.characterNama,
                                          style: const TextStyle(color: kSub, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(item.stage.namaStage,
                                      style: TextStyle(
                                          color: isDone ? kSub : kText, fontSize: 13)),

                                  Text(
                                    item.stage.hasProgressBar
                                        ? '${item.runsHariIni}x run  •  ${item.energiDipakai} ⚡'
                                        : '${item.runsHariIni}x run  •  ${item.energiDipakai} ⚡'
                                            '  •  ${item.stage.runsSelesai}/${item.stage.totalRuns} total',
                                    style: TextStyle(
                                        color: isDone ? kGreen : kSub, fontSize: 11),
                                  ),
                                  if (!item.stage.hasProgressBar &&
                                      item.stage.materialsInfo.isNotEmpty)
                                    Text(
                                      item.stage.materialsInfo
                                          .map((m) =>
                                              '~${m.jumlahPerRun.toStringAsFixed(1)} ${m.nama}')
                                          .join(', '),
                                      style: const TextStyle(color: kSub, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isDone,
                              onChanged: (v) => prov.toggleStage(
                                  item.stage.id, v ?? false, item.runsHariIni),
                              activeColor: kGreen,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Footer
          Container(
            color: kBG3,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('Sisa: ${plan.energiSisa} ⚡',
                    style: TextStyle(
                        color: plan.energiSisa >= 0 ? kGreen : kRed,
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: kYellow,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onPressed: () => _confirmReset(context, false),
                  child: const Text('↩️ Reset Hari', style: TextStyle(color: kBG, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: kAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onPressed: () => _showBonusDialog(context),
                  child: const Text('🎁 Bonus', style: TextStyle(color: kBG, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                if (!semua)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                    onPressed: () => _tandaiSemuaSelesai(context),
                    child: const Text('✅',
                        style: TextStyle(color: kBG, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWildernessRow(BuildContext context) {
    final prov = context.watch<CharacterUpgradeProvider>();
    final state = prov.state!;
    final isDone = state.wildernessSelesaiHariIni;

    final parts = <String>[];
    if (state.dailyDust > 0) parts.add('+${state.dailyDust} Dust');
    if (state.dailySharpodonty > 0) parts.add('+${state.dailySharpodonty} Sharpodonty');

    return Container(
      color: isDone ? kBG : kBG3,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wilderness (Daily Collect)',
                    style: TextStyle(color: kText, fontSize: 13)),
                Text(parts.join(', '),
                    style: TextStyle(color: isDone ? kGreen : kSub, fontSize: 11)),
              ],
            ),
          ),
          Checkbox(
            value: isDone,
            onChanged: (v) => prov.toggleWilderness(v ?? false),
            activeColor: kGreen,
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _importKarakter(BuildContext context) async {
    final prov = context.read<CharacterUpgradeProvider>();
    if (prov.state!.characters.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 4 karakter aktif.')),
      );
      return;
    }
    await prov.importCharacterFromFile();
  }

  Future<void> _tandaiSemuaSelesai(BuildContext context) async {
    await context.read<CharacterUpgradeProvider>().tandaiSemuaSelesai();
  }

  void _showKarakterDialog(BuildContext context) {
    final prov = context.read<CharacterUpgradeProvider>();
    final characters = prov.state!.characters;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: const Text('👤 Karakter Aktif', style: TextStyle(color: kAccent)),
        content: SizedBox(
          width: 350,
          child: characters.isEmpty
              ? const Text('Belum ada karakter.', style: TextStyle(color: kSub))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in characters)
                      ListTile(
                        title: Text(c.characterNama,
                            style: const TextStyle(color: kText)),
                        subtitle: Text(
                          'Total ${c.totalActivity} energi  •  ~${c.totalDays} hari',
                          style: const TextStyle(color: kSub, fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: kRed, size: 20),
                          onPressed: () {
                            prov.removeCharacter(c.id);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: kSub)),
          ),
        ],
      ),
    );
  }

  void _showEditStokDialog(BuildContext context) {
    final prov = context.read<CharacterUpgradeProvider>();
    final targets = prov.state!.materialTargets;
    final controllers = {
      for (final t in targets) t.nama: TextEditingController(text: t.stok.toString())
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: const Text('✏️ Edit Stok Material', style: TextStyle(color: kAccent)),
        content: SizedBox(
          width: 350,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final t in targets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text(t.nama,
                                style: const TextStyle(color: kText, fontSize: 12))),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controllers[t.nama],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: kText, fontSize: 12),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAccent),
                onPressed: () {
                  for (final t in targets) {
                    final val = int.tryParse(controllers[t.nama]?.text ?? '') ?? t.stok;
                    prov.editStokMaterial(t.nama, val);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Simpan', style: TextStyle(color: kBG)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBonusDialog(BuildContext context) {
    final prov = context.read<CharacterUpgradeProvider>();
    final targets = prov.state!.materialTargets;
    final controllers = {
      for (final t in targets) t.nama: TextEditingController(text: t.stok.toString())
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: const Text('🎁 Input Bonus Stok', style: TextStyle(color: kAccent)),
        content: SizedBox(
          width: 350,
          height: 400,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Isi total stok final (termasuk bonus):',
                    style: TextStyle(color: kSub, fontSize: 11)),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final t in targets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text(t.nama,
                                style: const TextStyle(color: kText, fontSize: 12))),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controllers[t.nama],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: kText, fontSize: 12),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAccent),
                onPressed: () {
                  final stokFinal = {
                    for (final t in targets)
                      t.nama: int.tryParse(controllers[t.nama]?.text ?? '') ?? t.stok
                  };
                  prov.applyBonus(stokFinal);
                  Navigator.pop(context);
                },
                child: const Text('Simpan', style: TextStyle(color: kBG)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfigDialog(BuildContext context) {
    final prov = context.read<CharacterUpgradeProvider>();
    final cEnergi = TextEditingController(
        text: prov.state!.energiPerHari.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: const Text('⚙️ Config', style: TextStyle(color: kAccent)),
        content: TextField(
          controller: cEnergi,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: kText),
          decoration: const InputDecoration(
              labelText: 'Energi per hari', labelStyle: TextStyle(color: kSub)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent),
            onPressed: () {
              final val = int.tryParse(cEnergi.text);
              if (val != null) prov.updateEnergi(val);
              Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: kBG)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, bool isAll) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: Text(isAll ? '⚠️ Reset All' : '↩️ Reset Hari Ini',
            style: const TextStyle(color: kRed)),
        content: Text(
          isAll
              ? 'Semua run progress dan stok material direset ke 0. Karakter aktif tetap ada.'
              : 'Centang hari ini dibatalkan, run progress dikembalikan.',
          style: const TextStyle(color: kText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              final prov = context.read<CharacterUpgradeProvider>();
              isAll ? prov.resetAll() : prov.resetHariIni();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: kBG3, foregroundColor: kText,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
