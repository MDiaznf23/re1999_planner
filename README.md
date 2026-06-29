# RE:1999 Daily Farming Planner

Aplikasi Android untuk merencanakan farming harian di game Reverse 1999. Aplikasi ini menghitung berapa round aktivitas yang perlu dikerjakan setiap hari agar target resource tercapai sebelum patch berakhir, berdasarkan energi yang tersedia.

Resource dan aktivitas bersifat custom. Aplikasi tidak terikat pada item atau kegiatan tertentu, sehingga bisa dipakai untuk patch apa saja, atau bahkan game lain dengan sistem energi harian yang serupa.

## Cara Kerja Aplikasi

### Konsep Dasar

Ada dua jenis data yang diatur sendiri oleh pengguna:

- **Resource**: item yang ingin dikumpulkan, misalnya Coin Event Shop atau Thoughts of Entirety. Setiap resource punya target jumlah yang ingin dicapai.
- **Activity**: kegiatan yang menghasilkan resource, misalnya Event Shop atau Pneuma Analysis. Setiap activity punya biaya energi per round dan menghasilkan satu atau lebih resource.

Berdasarkan dua data ini, aplikasi menghitung rencana harian secara otomatis.

### Mode Planner

Ada dua mode untuk membagi energi antar activity:

- **Mode Rata**: kebutuhan setiap activity dibagi rata berdasarkan sisa hari patch. Cocok dipakai kalau semua target ingin dikerjakan secara seimbang dari awal sampai akhir.
- **Mode All-In**: activity dengan prioritas tertinggi dikerjakan habis-habisan dulu menggunakan energi sebanyak mungkin, sisa energi baru dialokasikan ke activity berikutnya. Cocok dipakai kalau ada resource yang harus dikejar duluan.

Mode bisa diganti kapan saja, termasuk di tengah-tengah patch.

### Urutan Prioritas Activity

Setiap activity punya posisi urutan (1, 2, 3, dan seterusnya). Urutan ini menentukan activity mana yang dikerjakan lebih dulu, khususnya di Mode All-In.

Cara mengubah urutan:
- Tahan dan geser activity di halaman Manage Activity.
- Atau tap ikon edit prioritas dan masukkan angka posisi secara manual. Activity lain otomatis bergeser menyesuaikan.

### Alur Harian

1. Buka aplikasi, lihat daftar task hari ini di tab Daily Tasks.
2. Kerjakan activity di game, lalu centang activity yang sudah dikerjakan di aplikasi. Stok resource bertambah otomatis.
3. Kalau berubah pikiran, activity bisa diuncentang. Stok akan dikembalikan ke kondisi sebelum activity itu dicentang.
4. Setelah semua activity hari itu selesai dicentang, task otomatis tersimpan ke History dan hilang dari layar utama.
5. Pada jam reset yang ditentukan (default 17:00), task hari berikutnya muncul otomatis berdasarkan kalkulasi terbaru.

### Edit Stok dan Bonus

Ada dua cara mengubah stok secara manual, dengan tujuan berbeda:

- **Edit Stok**: dipakai untuk koreksi atau pengisian awal. Bisa dipakai kapan saja, tidak peduli status task hari ini. Tanggung jawab konsistensi data ada di pengguna.
- **Bonus**: dipakai untuk mencatat reward tambahan (misalnya dari event), hanya aktif setelah semua task hari ini selesai dicentang. Stok yang diisi di sini menjadi nilai final untuk planning hari berikutnya.

### Reset

Ada dua jenis reset, dengan dampak berbeda:

- **Reset Hari Ini**: membatalkan semua centang task hari ini, stok dikembalikan ke kondisi sebelum task hari itu dikerjakan. Resource, activity, dan history tidak terpengaruh.
- **Reset All**: stok semua resource dikembalikan ke 0, history dihapus. Resource dan activity yang sudah dibuat tetap ada.

Reset Save dipakai saat mulai patch baru. Alurnya: update tanggal patch di Config, update stok awal lewat Edit Stok kalau berbeda dari sebelumnya, lalu tekan Reset All.

### Export dan Import Config

Resource, activity, dan planner config bisa di-export ke file JSON dan di-import kembali. Stok dan history tidak ikut di-export, karena keduanya bersifat personal dan berbeda untuk setiap pengguna.

Import akan mengganti seluruh resource dan activity yang ada. Stok otomatis reset ke 0 setelah import. Fitur ini berguna untuk:

- Berbagi konfigurasi antar pemain.
- Menyiapkan konfigurasi baru untuk patch berikutnya tanpa input manual dari awal.

Contoh file konfigurasi tersedia di folder `examples/`.

## Instalasi

### Mengunduh APK Langsung

Unduh file APK dari halaman Releases di repository ini, lalu install langsung ke perangkat Android. Aktifkan opsi "Install from unknown sources" di pengaturan Android kalau diminta.

### Build dari Source

Persyaratan: Flutter SDK sudah terinstall.

```
git clone <url-repo-ini>
cd re1999_sdk
flutter pub get
flutter build apk --release
```

File APK hasil build ada di:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Struktur Data

Detail struktur data dan logika kalkulasi ada di:

- `lib/models/` — definisi Resource, Activity, Planner Config, History
- `lib/logic/daily_plan_v2.dart` — logika kalkulasi rencana harian untuk kedua mode
- `lib/providers/app_provider_v2.dart` — state management dan seluruh aksi pengguna

## Lisensi

MIT LICENSE
