import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider_v2.dart';
import '../models/activity_model.dart';
import '../widgets/home_screen_colors.dart';

class ManageActivityScreen extends StatelessWidget {
  const ManageActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProviderV2>();
    final activities = List<Activity>.from(prov.state!.activities)
      ..sort((a, b) => a.prioritas.compareTo(b.prioritas));

    return Scaffold(
      backgroundColor: kBG,
      appBar: AppBar(
        backgroundColor: kBG3,
        title: const Text('Manage Activity', style: TextStyle(color: kAccent, fontSize: 16)),
        iconTheme: const IconThemeData(color: kAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kAccent),
            onPressed: () => _showEditDialog(context, null),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: kBG2,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Tahan & geser ikon ☰ untuk ubah urutan. Atau tap ikon edit untuk input angka prioritas manual.',
                style: TextStyle(color: kSub, fontSize: 11),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: activities.length,
                onReorder: (oldIndex, newIndex) {
                  context.read<AppProviderV2>().reorderActivityByDrag(oldIndex, newIndex);
                },
                itemBuilder: (context, i) {
                  final a = activities[i];
                  final hasilStr = a.hasil.map((h) {
                    final res = prov.state!.getResourceById(h.resourceId);
                    return '+${h.jumlahPerRound} ${res?.nama ?? "?"}';
                  }).join(', ');

                  return Card(
                    key: ValueKey(a.id),
                    color: kBG2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: kBG3,
                        radius: 14,
                        child: Text('${a.prioritas}', style: const TextStyle(color: kAccent, fontSize: 11)),
                      ),
                      title: Text(
                        a.nama,
                        style: const TextStyle(color: kText, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${a.isGratis ? "GRATIS" : "${a.energiPerRound}e"} → $hasilStr',
                        style: const TextStyle(color: kSub, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.low_priority, color: kYellow, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _showPriorityDialog(context, a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: kAccent, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _showEditDialog(context, a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: kRed, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _confirmDelete(context, a.id, a.nama),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.drag_handle, color: kSub, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityDialog(BuildContext context, Activity a) {
    final cPrio = TextEditingController(text: a.prioritas.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: const Text('Ubah Prioritas', style: TextStyle(color: kYellow)),
        content: TextField(
          controller: cPrio,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: kText),
          decoration: const InputDecoration(labelText: 'Posisi urutan (1 = tertinggi)', labelStyle: TextStyle(color: kSub)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kYellow),
            onPressed: () {
              final newPrio = int.tryParse(cPrio.text);
              if (newPrio != null) {
                context.read<AppProviderV2>().setActivityPriority(a.id, newPrio);
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: kBG)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Activity? existing) {
    final prov = context.read<AppProviderV2>();
    final cNama = TextEditingController(text: existing?.nama ?? '');
    final cEnergi = TextEditingController(text: existing?.energiPerRound.toString() ?? '0');
    final cMaxRound = TextEditingController(text: existing?.maxRoundPerHari?.toString() ?? '');

    final Map<String, TextEditingController> hasilControllers = {};
    for (final res in prov.state!.resources) {
      final existingHasil = existing?.hasil.firstWhere(
        (h) => h.resourceId == res.id,
        orElse: () => ActivityResult(resourceId: res.id, jumlahPerRound: 0),
      );
      hasilControllers[res.id] = TextEditingController(text: (existingHasil?.jumlahPerRound ?? 0).toString());
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: Text(existing == null ? 'Tambah Activity' : 'Edit Activity', style: const TextStyle(color: kAccent)),
        content: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cNama,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(labelText: 'Nama Activity', labelStyle: TextStyle(color: kSub)),
                ),
                TextField(
                  controller: cEnergi,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(labelText: 'Energi per round (0 = gratis)', labelStyle: TextStyle(color: kSub)),
                ),
                TextField(
                  controller: cMaxRound,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(labelText: 'Max round/hari (kosong = unlimited)', labelStyle: TextStyle(color: kSub)),
                ),
                const Divider(color: kSub),
                const Align(alignment: Alignment.centerLeft, child: Text('Hasil per round:', style: TextStyle(color: kYellow, fontSize: 12))),
                if (prov.state!.resources.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Belum ada resource. Buat resource dulu.', style: TextStyle(color: kRed, fontSize: 11)),
                  ),
                for (final res in prov.state!.resources)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(res.nama, style: const TextStyle(color: kText, fontSize: 12))),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: hasilControllers[res.id],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: kText, fontSize: 12),
                            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent),
            onPressed: () {
              final namaVal = cNama.text.trim();
              if (namaVal.isEmpty) return;
              final energiVal = int.tryParse(cEnergi.text) ?? 0;
              final maxRoundVal = cMaxRound.text.trim().isEmpty ? null : int.tryParse(cMaxRound.text);

              final hasilList = <ActivityResult>[];
              hasilControllers.forEach((resId, ctrl) {
                final jumlah = int.tryParse(ctrl.text) ?? 0;
                if (jumlah > 0) hasilList.add(ActivityResult(resourceId: resId, jumlahPerRound: jumlah));
              });

              if (existing == null) {
                final newPriority = prov.state!.activities.length + 1;
                prov.addActivity(namaVal, energiVal, hasilList, newPriority, maxRound: maxRoundVal);
              } else {
                prov.updateActivity(existing.id, nama: namaVal, energiPerRound: energiVal, hasil: hasilList, maxRound: maxRoundVal);
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: kBG)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: const Text('Hapus Activity?', style: TextStyle(color: kRed)),
        content: Text('Hapus "$nama"?', style: const TextStyle(color: kText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              context.read<AppProviderV2>().deleteActivity(id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
