import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_upgrade_provider.dart';
import '../widgets/home_screen_colors.dart';

class CharacterHistoryScreen extends StatelessWidget {
  const CharacterHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CharacterUpgradeProvider>();
    final history = prov.state!.history;

    return Scaffold(
      backgroundColor: kBG,
      appBar: AppBar(
        backgroundColor: kBG3,
        title: const Text('History Character Upgrade',
            style: TextStyle(color: kAccent, fontSize: 16)),
        iconTheme: const IconThemeData(color: kAccent),
      ),
      body: SafeArea(
        child: history.isEmpty
            ? const Center(
                child: Text('Belum ada history.', style: TextStyle(color: kSub)))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: history.length,
                itemBuilder: (context, i) {
                  final h = history[i];
                  return Card(
                    color: kBG2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      title: Text(h.tanggal,
                          style: const TextStyle(
                              color: kAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('${h.stageSelesai.length} stage dikerjakan',
                          style: const TextStyle(color: kSub, fontSize: 11)),
                      iconColor: kAccent,
                      collapsedIconColor: kSub,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stage dikerjakan:',
                                  style: TextStyle(color: kYellow, fontSize: 12)),
                              for (final s in h.stageSelesai)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, top: 2),
                                  child: Text('• $s',
                                      style: const TextStyle(color: kText, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
