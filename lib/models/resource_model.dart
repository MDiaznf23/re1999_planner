class Resource {
  String id;
  String nama;
  int target;
  int stok;

  Resource({
    required this.id,
    required this.nama,
    required this.target,
    required this.stok,
  });

  factory Resource.fromJson(Map<String, dynamic> j) => Resource(
    id: j['id'],
    nama: j['nama'],
    target: j['target'] ?? 0,
    stok: j['stok'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'target': target,
    'stok': stok,
  };

  Resource copyWith({String? nama, int? target, int? stok}) => Resource(
    id: id,
    nama: nama ?? this.nama,
    target: target ?? this.target,
    stok: stok ?? this.stok,
  );
}
