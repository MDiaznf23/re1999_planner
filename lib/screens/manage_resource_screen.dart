import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider_v2.dart';
import '../widgets/home_screen_colors.dart';

class ManageResourceScreen extends StatelessWidget {
  const ManageResourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProviderV2>();
    final resources = prov.state!.resources;

    return Scaffold(
      backgroundColor: kBG,
      appBar: AppBar(
        backgroundColor: kBG3,
        title: const Text('Manage Resource', style: TextStyle(color: kAccent, fontSize: 16)),
        iconTheme: const IconThemeData(color: kAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kAccent),
            onPressed: () => _showEditDialog(context, null, '', 0),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: resources.length,
          itemBuilder: (context, i) {
            final r = resources[i];
            return Card(
              color: kBG2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(r.nama, style: const TextStyle(color: kText, fontSize: 13)),
                subtitle: Text('Stok: ${r.stok} / Target: ${r.target}',
                  style: const TextStyle(color: kSub, fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: kAccent, size: 20),
                        onPressed: () => _showEditDialog(context, r.id, r.nama, r.target),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: kRed, size: 20),
                        onPressed: () => _confirmDelete(context, r.id, r.nama),
                      ),
                    ],
                  ),
                ),
              );
            },
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String? id, String nama, int target) {
    final cNama = TextEditingController(text: nama);
    final cTarget = TextEditingController(text: target.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBG2,
        title: Text(id == null ? 'Tambah Resource' : 'Edit Resource', style: const TextStyle(color: kAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cNama,
              style: const TextStyle(color: kText),
              decoration: const InputDecoration(labelText: 'Nama Resource', labelStyle: TextStyle(color: kSub)),
            ),
            TextField(
              controller: cTarget,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kText),
              decoration: const InputDecoration(labelText: 'Target', labelStyle: TextStyle(color: kSub)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent),
            onPressed: () {
              final prov = context.read<AppProviderV2>();
              final namaVal = cNama.text.trim();
              final targetVal = int.tryParse(cTarget.text) ?? 0;
              if (namaVal.isEmpty) return;

              if (id == null) {
                prov.addResource(namaVal, targetVal);
              } else {
                prov.updateResource(id, nama: namaVal, target: targetVal);
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
        title: const Text('Hapus Resource?', style: TextStyle(color: kRed)),
        content: Text('Hapus "$nama"? Activity yang menghasilkan resource ini juga ikut terdampak.',
            style: const TextStyle(color: kText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () {
              context.read<AppProviderV2>().deleteResource(id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
