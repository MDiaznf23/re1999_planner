import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider_v2.dart';
import '../widgets/home_screen_colors.dart';

void showEditStokDialog(BuildContext context) {
  final prov = context.read<AppProviderV2>();
  final resources = prov.state!.resources;
  final entries = {for (final r in resources) r.id: TextEditingController(text: r.stok.toString())};

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kBG2,
      title: const Text('✏️ Edit Stok Manual', style: TextStyle(color: kAccent, fontSize: 14)),
      content: SizedBox(
        width: 350,
        height: 400,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Edit stok bebas kapan saja — tidak mempengaruhi status task hari ini.',
                style: TextStyle(color: kSub, fontSize: 11),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final r in resources)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text(r.nama, style: const TextStyle(color: kText, fontSize: 12))),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: entries[r.id],
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kAccent),
          onPressed: () {
            final stokBaru = {for (final e in entries.entries) e.key: int.tryParse(e.value.text) ?? 0};
            prov.editStokManual(stokBaru);
            Navigator.pop(context);
          },
          child: const Text('Simpan', style: TextStyle(color: kBG)),
        ),
      ],
    ),
  );
}
