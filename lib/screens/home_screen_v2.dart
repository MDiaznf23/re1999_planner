import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider_v2.dart';
import '../models/planner_config_model.dart';
import '../logic/game_day.dart';
import '../widgets/home_screen_colors.dart';
import 'manage_resource_screen.dart';
import 'manage_activity_screen.dart';
import 'history_screen.dart';
import 'bonus_dialog.dart';
import 'edit_stok_dialog.dart';
import 'import_export_dialog.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});
  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 60));
      if (!mounted) return false;
      await context.read<AppProviderV2>().checkDayRollover();
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProviderV2>();

    if (prov.loading) {
      return const Scaffold(backgroundColor: kBG, body: Center(child: CircularProgressIndicator(color: kAccent)));
    }

    final state = prov.state!;
    final cfg = state.plannerConfig;
    final gameToday = formatGameDate(getGameDay(cfg.gameDayResetHour));
    final planResult = prov.planResult;

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
                  const Text('REVERSE 1999 PLANNER',
                      style: TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '📅  $gameToday  ⏳ ${prov.sisaHari} hari  ⚡ ${cfg.energiPerHari}/hari  '
                    '⚙️  ${cfg.mode == PlannerMode.rata ? "Mode Rata" : "Mode All-In"}',
                    style: const TextStyle(color: kSub, fontSize: 11),
                  )
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
                    _btn(context, 'Resource', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageResourceScreen()))),
                    _btn(context, 'Activity', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageActivityScreen()))),
                    _btn(context, 'History', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                    _btn(context, 'Mode', () => prov.togglePlannerMode()),
                    _btn(context, 'Config', () => _showConfigDialog(context)),
                    _btn(context, 'Export/Import', () => showImportExportDialog(context)),
                    _btn(context, 'Reset All', () => _confirmReset(context, true)),
                  ],
                ),
              ),
            ),

            // ── Peringatan (mode all-in) ──────────────────────────────────
            if (planResult != null && planResult.peringatan.isNotEmpty)
              Material(
                color: kRed.withOpacity(0.15),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    iconColor: kRed,
                    collapsedIconColor: kRed,
                    title: Text(
                      '⚠️ Peringatan (${planResult.peringatan.length})',
                      style: const TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final p in planResult.peringatan)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('• $p', style: const TextStyle(color: kRed, fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Main Area: Resource summary + Task list ──────────────────
            Expanded(
              child: _buildMainArea(context, planResult),
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

  Widget _buildSelesaiView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Semua task hari ini sudah selesai!',
                style: TextStyle(color: kGreen, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Sudah tersimpan di History.',
                style: TextStyle(color: kSub, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: kYellow, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onPressed: () => _confirmReset(context, false),
                  child: const Text('↩️ Reset Hari', style: TextStyle(color: kBG, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: kAccent, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onPressed: () => showBonusDialog(context),
                  child: const Text('Input Bonus', style: TextStyle(color: kBG, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainArea(BuildContext context, planResult) {
    final prov = context.watch<AppProviderV2>();
    final state = prov.state!;
    final isWide = MediaQuery.of(context).size.width >= 720;

    final taskArea = state.taskHariIniSudahSelesaiSemua
        ? _buildSelesaiView(context)
        : _buildTaskPanel(context, planResult);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 280, child: _buildResourcePanel(context)),
          Expanded(child: taskArea),
        ],
      );
    } else {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: kAccent,
              labelColor: kAccent,
              unselectedLabelColor: kSub,
              tabs: [Tab(text: '📦 Stok'), Tab(text: '📋 Tasks')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildResourcePanel(context),
                  taskArea,
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildResourcePanel(BuildContext context) {
    final prov = context.watch<AppProviderV2>();
    final state = prov.state!;
    final sortedResources = state.resources;

    return Container(
      color: kBG2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text('STOK & TARGET', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: kBG3,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => showEditStokDialog(context),
                  child: const Text('✏️ Edit', style: TextStyle(color: kText, fontSize: 10)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (int i = 0; i < sortedResources.length; i++) ...[
                  if (i > 0 && i % 3 == 0)
                    const Divider(color: kSub, thickness: 0.5, height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(sortedResources[i].nama, style: const TextStyle(color: kText, fontSize: 11))),
                            Text('${sortedResources[i].stok}/${sortedResources[i].target}',
                                style: TextStyle(
                                  color: sortedResources[i].stok >= sortedResources[i].target
                                      ? kGreen
                                      : (sortedResources[i].stok >= sortedResources[i].target * 0.5 ? kYellow : kRed),
                                  fontSize: 11, fontFamily: 'Courier',
                                )),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: sortedResources[i].target > 0
                                ? (sortedResources[i].stok / sortedResources[i].target).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 5,
                            backgroundColor: kBG,
                            valueColor: AlwaysStoppedAnimation(
                              sortedResources[i].stok >= sortedResources[i].target
                                  ? kGreen
                                  : (sortedResources[i].stok >= sortedResources[i].target * 0.5 ? kYellow : kRed),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPanel(BuildContext context, planResult) {
    final prov = context.watch<AppProviderV2>();
    final state = prov.state!;

    if (planResult == null) return const SizedBox();

    return Container(
      color: kBG2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text('DAILY TASKS', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: planResult.items.length,
              itemBuilder: (context, i) {
                final item = planResult.items[i];
                if (item.round <= 0 && !item.activity.isGratis) return const SizedBox();
                final isDone = state.activitySelesaiHariIni.contains(item.activity.id);

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
                            Text(item.activity.nama, style: TextStyle(color: isDone ? kSub : kText, fontSize: 13)),
                            Text(
                              '${item.round}x  •  ${item.energi > 0 ? "${item.energi} ⚡" : "GRATIS"}  •  ${item.hasilText}',
                              style: TextStyle(color: isDone ? kGreen : kSub, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: isDone,
                        onChanged: (v) => context.read<AppProviderV2>().toggleActivity(item.activity.id, v ?? false),
                        activeColor: kGreen,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: kBG3,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('Sisa: ${planResult.energiSisa} ⚡',
                    style: TextStyle(color: planResult.energiSisa >= 0 ? kGreen : kRed, fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: kYellow, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onPressed: () => _confirmReset(context, false),
                  child: const Text('↩️ Reset Task', style: TextStyle(color: kBG, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: kAccent, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onPressed: () => showBonusDialog(context),
                  child: const Text('Bonus', style: TextStyle(color: kBG, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                  onPressed: () => context.read<AppProviderV2>().tandaiSemuaSelesai(),
                  child: const Text('✅', style: TextStyle(color: kBG, fontSize: 12)),
                ),
              ],
            ),
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
        style: TextButton.styleFrom(backgroundColor: kBG3, foregroundColor: kText, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  void _confirmReset(BuildContext context, bool isAll) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: Text(isAll ? 'Reset All' : 'Reset Hari Ini', style: const TextStyle(color: kRed)),
        content: Text(
          isAll
              ? 'Semua stok jadi 0, history terhapus. Resource & Activity tetap ada.'
              : 'Centang hari ini dibatalkan, stok balik ke sebelum centang hari ini.',
          style: const TextStyle(color: kText),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              final prov = context.read<AppProviderV2>();
              isAll ? prov.resetAll() : prov.resetHariIni();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog(BuildContext context) {
    final prov = context.read<AppProviderV2>();
    final cfg = prov.state!.plannerConfig;
    final cEnergi = TextEditingController(text: cfg.energiPerHari.toString());
    final cReset = TextEditingController(text: cfg.gameDayResetHour.toString());
    final cMulai = TextEditingController(text: cfg.patch.tanggalMulai);
    final cAkhir = TextEditingController(text: cfg.patch.tanggalAkhir);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: const Text('⚙️ Config', style: TextStyle(color: kAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cEnergi, keyboardType: TextInputType.number, style: const TextStyle(color: kText), decoration: const InputDecoration(labelText: 'Energi/hari', labelStyle: TextStyle(color: kSub))),
            TextField(controller: cReset, keyboardType: TextInputType.number, style: const TextStyle(color: kText), decoration: const InputDecoration(labelText: 'Jam reset', labelStyle: TextStyle(color: kSub))),
            TextField(controller: cMulai, style: const TextStyle(color: kText), decoration: const InputDecoration(labelText: 'Tanggal mulai', labelStyle: TextStyle(color: kSub))),
            TextField(controller: cAkhir, style: const TextStyle(color: kText), decoration: const InputDecoration(labelText: 'Tanggal akhir', labelStyle: TextStyle(color: kSub))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent),
            onPressed: () {
              prov.updatePlannerConfig(
                int.tryParse(cEnergi.text), int.tryParse(cReset.text), cMulai.text, cAkhir.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: kBG)),
          ),
        ],
      ),
    );
  }
}
