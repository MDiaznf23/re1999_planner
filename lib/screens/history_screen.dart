import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider_v2.dart';
import '../widgets/home_screen_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProviderV2>();
    final history = prov.state!.history;

    return Scaffold(
      backgroundColor: kBG,
      appBar: AppBar(
        backgroundColor: kBG3,
        title: const Text('📜 History', style: TextStyle(color: kAccent, fontSize: 16)),
        iconTheme: const IconThemeData(color: kAccent),
      ),
      body: history.isEmpty
          ? const Center(child: Text('Belum ada history.', style: TextStyle(color: kSub)))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final h = history[i];
                return Card(
                  color: kBG2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    title: Text(h.tanggal, style: const TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('${h.activitySelesai.length} activity dikerjakan', style: const TextStyle(color: kSub, fontSize: 11)),
                    iconColor: kAccent,
                    collapsedIconColor: kSub,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Activity:', style: TextStyle(color: kYellow, fontSize: 12)),
                            for (final akt in h.activitySelesai)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Text('• $akt', style: const TextStyle(color: kText, fontSize: 12)),
                              ),
                            const SizedBox(height: 8),
                            const Text('Stok akhir hari itu:', style: TextStyle(color: kYellow, fontSize: 12)),
                            for (final entry in h.stokAkhir.entries)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Text(
                                  '• ${prov.state!.getResourceById(entry.key)?.nama ?? entry.key}: ${entry.value}',
                                  style: const TextStyle(color: kText, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
