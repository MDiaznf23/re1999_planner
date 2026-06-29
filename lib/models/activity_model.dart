class ActivityResult {
  String resourceId;
  int jumlahPerRound;

  ActivityResult({required this.resourceId, required this.jumlahPerRound});

  factory ActivityResult.fromJson(Map<String, dynamic> j) => ActivityResult(
    resourceId: j['resource_id'],
    jumlahPerRound: j['jumlah_per_round'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'resource_id': resourceId,
    'jumlah_per_round': jumlahPerRound,
  };
}

class Activity {
  String id;
  String nama;
  int energiPerRound;
  List<ActivityResult> hasil;
  int prioritas;
  int? maxRoundPerHari; // null = unlimited (dibatasi energi/target saja)

  Activity({
    required this.id,
    required this.nama,
    required this.energiPerRound,
    required this.hasil,
    required this.prioritas,
    this.maxRoundPerHari,
  });

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'],
    nama: j['nama'],
    energiPerRound: j['energi_per_round'] ?? 0,
    hasil: (j['hasil'] as List).map((h) => ActivityResult.fromJson(h)).toList(),
    prioritas: j['prioritas'] ?? 99,
    maxRoundPerHari: j['max_round_per_hari'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'energi_per_round': energiPerRound,
    'hasil': hasil.map((h) => h.toJson()).toList(),
    'prioritas': prioritas,
    'max_round_per_hari': maxRoundPerHari,
  };

  bool get isGratis => energiPerRound == 0;
}
