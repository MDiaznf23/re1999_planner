class MaterialTarget {
  String nama;
  int target;
  int stok;

  MaterialTarget({required this.nama, required this.target, required this.stok});

  factory MaterialTarget.fromJson(Map<String, dynamic> j) => MaterialTarget(
    nama: j['nama'],
    target: j['target'] ?? 0,
    stok: j['stok'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'target': target,
    'stok': stok,
  };
}
