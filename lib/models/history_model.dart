class HistoryEntry {
  String tanggal;
  List<String> activitySelesai; // list nama activity yang dikerjakan
  Map<String, int> stokAkhir;   // snapshot stok di akhir hari itu (resourceId -> jumlah)

  HistoryEntry({
    required this.tanggal,
    required this.activitySelesai,
    required this.stokAkhir,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
    tanggal: j['tanggal'],
    activitySelesai: List<String>.from(j['activity_selesai'] ?? []),
    stokAkhir: Map<String, int>.from(j['stok_akhir'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'tanggal': tanggal,
    'activity_selesai': activitySelesai,
    'stok_akhir': stokAkhir,
  };
}
