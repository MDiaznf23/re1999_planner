import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider_v2.dart';
import '../widgets/home_screen_colors.dart';

void showImportExportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kBG2,
      title: const Text('📤 Export / Import Config', style: TextStyle(color: kAccent, fontSize: 14)),
      content: const Text(
        'Export: simpan resource, activity, dan planner config ke file JSON.\n\n'
        'Import: ganti semua resource & activity dengan file JSON. Stok & history TIDAK terpengaruh, tapi semua resource otomatis reset ke 0.',
        style: TextStyle(color: kText, fontSize: 12),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: kSub)),
        ),
        TextButton(
          style: TextButton.styleFrom(backgroundColor: kAccent, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          onPressed: () async {
            final path = await context.read<AppProviderV2>().exportToFile();
            Navigator.pop(context);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tersimpan di: $path')),
              );
            }
          },
          child: const Text('Export', style: TextStyle(color: kBG)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kRed),
          onPressed: () => _confirmImport(context),
          child: const Text('Import'),
        ),
      ],
    ),
  );
}

void _confirmImport(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kBG2,
      title: const Text('⚠️ Konfirmasi Import', style: TextStyle(color: kRed)),
      content: const Text(
        'Semua resource & activity akan DIGANTI total dengan isi file. Stok akan reset 0. Lanjutkan?',
        style: TextStyle(color: kText),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: kSub))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kRed),
          onPressed: () async {
            final prov = context.read<AppProviderV2>();
            final success = await prov.pickAndImportFile();
            Navigator.pop(context); // tutup confirm dialog
            Navigator.pop(context); // tutup export/import dialog
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Import berhasil!' : 'Import dibatalkan/gagal.')),
              );
            }
          },
          child: const Text('Ya, Import'),
        ),
      ],
    ),
  );
}
