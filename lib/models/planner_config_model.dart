enum PlannerMode { rata, allIn }

class PatchInfo {
  String tanggalMulai;
  String tanggalAkhir;
  PatchInfo({required this.tanggalMulai, required this.tanggalAkhir});
  factory PatchInfo.fromJson(Map<String, dynamic> j) => PatchInfo(
    tanggalMulai: j['tanggal_mulai'],
    tanggalAkhir: j['tanggal_akhir'],
  );
  Map<String, dynamic> toJson() => {'tanggal_mulai': tanggalMulai, 'tanggal_akhir': tanggalAkhir};
}

class PlannerConfig {
  PatchInfo patch;
  int energiPerHari;
  int gameDayResetHour;
  PlannerMode mode;

  PlannerConfig({
    required this.patch,
    required this.energiPerHari,
    required this.gameDayResetHour,
    required this.mode,
  });

  factory PlannerConfig.fromJson(Map<String, dynamic> j) => PlannerConfig(
    patch: PatchInfo.fromJson(j['patch']),
    energiPerHari: j['energi_per_hari'] ?? 100,
    gameDayResetHour: j['game_day_reset_hour'] ?? 17,
    mode: (j['mode'] == 'all_in') ? PlannerMode.allIn : PlannerMode.rata,
  );

  Map<String, dynamic> toJson() => {
    'patch': patch.toJson(),
    'energi_per_hari': energiPerHari,
    'game_day_reset_hour': gameDayResetHour,
    'mode': mode == PlannerMode.allIn ? 'all_in' : 'rata',
  };
}
