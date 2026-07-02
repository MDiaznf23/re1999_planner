enum StageKategori { resource, insight, farming }

class MaterialInfo {
  String nama;

  double jumlahPerRun;

  MaterialInfo({required this.nama, required this.jumlahPerRun});

  factory MaterialInfo.fromJson(Map<String, dynamic> j) => MaterialInfo(
    nama: j['Material'] ?? j['nama'],
    jumlahPerRun: ((j['Quantity'] ?? j['jumlah_per_run'] ?? 0) as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'jumlah_per_run': jumlahPerRun,
  };
}

class StageTask {
  String id;
  String characterNama;
  StageKategori kategori;
  String namaStage;
  int totalRuns;
  int runsSelesai;
  int energiPerRun;
  int prioritas;
  List<MaterialInfo> materialsInfo;

  StageTask({
    required this.id,
    required this.characterNama,
    required this.kategori,
    required this.namaStage,
    required this.totalRuns,
    required this.runsSelesai,
    required this.energiPerRun,
    required this.prioritas,
    required this.materialsInfo,
  });

  bool get hasProgressBar => kategori != StageKategori.farming;
  bool get selesai => runsSelesai >= totalRuns;

  factory StageTask.fromJson(Map<String, dynamic> j) => StageTask(
    id: j['id'],
    characterNama: j['character_nama'],
    kategori: StageKategori.values.firstWhere((k) => k.name == j['kategori']),
    namaStage: j['nama_stage'],
    totalRuns: (j['total_runs'] as num).round(),
    runsSelesai: (j['runs_selesai'] as num? ?? 0).round(),
    energiPerRun: (j['energi_per_run'] as num).round(),
    prioritas: j['prioritas'] ?? 99,
    materialsInfo: (j['materials_info'] as List).map((m) => MaterialInfo.fromJson(m)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'character_nama': characterNama,
    'kategori': kategori.name,
    'nama_stage': namaStage,
    'total_runs': totalRuns,
    'runs_selesai': runsSelesai,
    'energi_per_run': energiPerRun,
    'prioritas': prioritas,
    'materials_info': materialsInfo.map((m) => m.toJson()).toList(),
  };
}
