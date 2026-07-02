import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_upgrade_provider.dart';
import '../models/stage_task_model.dart';
import '../widgets/home_screen_colors.dart';

class FarmingProgressScreen extends StatelessWidget {
  const FarmingProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CharacterUpgradeProvider>();
    final state = prov.state;

    final farmingStages = (state?.stageTasks ?? <StageTask>[])
        .where((s) => s.kategori == StageKategori.farming)
        .toList()
      ..sort((a, b) => a.prioritas.compareTo(b.prioritas));

    final selesaiCount = farmingStages.where((s) => s.selesai).length;

    return Scaffold(
      backgroundColor: kBG,
      appBar: AppBar(
        backgroundColor: kBG3,
        foregroundColor: kText,
        title: const Text('Farming Progress', style: TextStyle(fontSize: 15)),
      ),
      body: farmingStages.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🌾', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 8),
                    Text('Belum ada stage farming.',
                        style: TextStyle(color: kSub, fontSize: 13)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: kBG2,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    '$selesaiCount / ${farmingStages.length} stage selesai',
                    style: const TextStyle(
                        color: kAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: farmingStages.length,
                    itemBuilder: (context, i) {
                      final stage = farmingStages[i];
                      final selesai = stage.selesai;
                      final progress = stage.totalRuns > 0
                          ? (stage.runsSelesai / stage.totalRuns).clamp(0.0, 1.0)
                          : 0.0;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: kBG2,
                          borderRadius: BorderRadius.circular(6),
                          border: selesai
                              ? Border.all(color: kGreen.withOpacity(0.4))
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kSub.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('FARMING',
                                      style: TextStyle(color: kSub, fontSize: 9)),
                                ),
                                const SizedBox(width: 6),
                                Text(stage.characterNama,
                                    style: const TextStyle(color: kSub, fontSize: 10)),
                                const Spacer(),
                                if (selesai)
                                  const Text('✅ Selesai',
                                      style: TextStyle(color: kGreen, fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(stage.namaStage,
                                style: TextStyle(
                                    color: selesai ? kSub : kText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: kBG,
                                      valueColor: AlwaysStoppedAnimation(
                                          selesai ? kGreen : kAccent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${stage.runsSelesai}/${stage.totalRuns}',
                                    style: TextStyle(
                                        color: selesai ? kGreen : kText,
                                        fontSize: 11, fontFamily: 'Courier')),
                              ],
                            ),
                            if (stage.materialsInfo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Estimasi hasil: ${stage.materialsInfo.map((m) => '~${(m.jumlahPerRun * stage.totalRuns).toStringAsFixed(0)} ${m.nama}').join(', ')}',
                                style: const TextStyle(color: kSub, fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
