import 'package:intl/intl.dart';

DateTime getGameDay(int resetHour) {
  final now = DateTime.now();
  if (now.hour < resetHour) {
    return DateTime(now.year, now.month, now.day - 1);
  }
  return DateTime(now.year, now.month, now.day);
}

int hitungSisaHari(String tanggalAkhirStr, int resetHour) {
  final akhir = DateTime.parse(tanggalAkhirStr);
  final hariIni = getGameDay(resetHour);
  final delta = akhir.difference(hariIni).inDays + 1;
  return delta < 0 ? 0 : delta;
}

String formatGameDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
