# RE:1999 Daily Farming Planner

Aplikasi Android untuk merencanakan farming harian di game Reverse 1999. Ada dua modul utama yang bisa diakses lewat bottom navigation bar: Daily Resource Planner dan Character Upgrade Planner.

## Modul 1: Daily Resource Planner

Planner generik berbasis resource dan activity yang sepenuhnya custom. Cocok dipakai untuk target apa saja, bukan terikat pada item atau kegiatan tertentu.

### Konsep Dasar

Ada dua jenis data yang diatur sendiri oleh pengguna:

- **Resource**: item yang ingin dikumpulkan, misalnya Coin Event Shop atau Thoughts of Entirety. Setiap resource punya target jumlah yang ingin dicapai.
- **Activity**: kegiatan yang menghasilkan resource, misalnya Event Shop atau Pneuma Analysis. Setiap activity punya biaya energi per round dan menghasilkan satu atau lebih resource.

Berdasarkan dua data ini, aplikasi menghitung rencana harian secara otomatis.

### Mode Planner

- **Mode Rata**: kebutuhan setiap activity dibagi rata berdasarkan sisa hari patch.
- **Mode All-In**: activity dengan prioritas tertinggi dikerjakan habis-habisan dulu, sisa energi baru dialokasikan ke activity berikutnya.

Mode bisa diganti kapan saja, termasuk di tengah-tengah patch.

### Urutan Prioritas Activity

Setiap activity punya posisi urutan. Urutan ini menentukan activity mana yang dikerjakan lebih dulu, khususnya di Mode All-In. Bisa diubah lewat drag di halaman Manage Activity, atau lewat input angka posisi manual.

### Alur Harian

1. Buka aplikasi, lihat daftar task hari ini di tab Daily Tasks.
2. Kerjakan activity di game, lalu centang di aplikasi. Stok resource bertambah otomatis.
3. Activity bisa diuncentang. Stok dikembalikan ke kondisi sebelum activity itu dicentang.
4. Setelah semua activity hari itu dicentang, task otomatis tersimpan ke History dan hilang dari layar.
5. Pada jam reset (default 17:00), task hari berikutnya muncul otomatis berdasarkan kalkulasi terbaru.

### Edit Stok dan Bonus

- **Edit Stok**: koreksi atau pengisian awal, bisa dipakai kapan saja.
- **Bonus**: mencatat reward tambahan, hanya aktif setelah semua task hari ini selesai dicentang.

### Reset

- **Reset Hari Ini**: membatalkan semua centang task hari ini, stok dikembalikan ke kondisi sebelum task hari itu dikerjakan. Resource, activity, dan history tidak terpengaruh.
- **Reset All**: stok semua resource dikembalikan ke 0, history dihapus. Resource dan activity tetap ada.

### Export dan Import Config

Resource, activity, dan planner config bisa di-export ke file JSON dan di-import kembali. Stok dan history tidak ikut di-export. Import akan mengganti seluruh resource dan activity yang ada, dan stok otomatis reset ke 0.

## Modul 2: Character Upgrade Planner

Planner khusus untuk farming upgrade karakter. Berbeda dari Modul 1 yang generik, modul ini menerima total runs yang sudah dihitung oleh solver eksternal berbasis website, lalu membagi total runs itu ke hari-hari berdasarkan energi harian.

### Alur Import Karakter

1. Buka website [Kornblume Planner](https://mdiaznf23.github.io/kornblume_planner_json_data/), isi data yang dibutuhkan, lalu unduh file JSON hasilnya per karakter.
2. Import file JSON lewat tombol Import Karakter.
3. Aplikasi memeriksa nama karakter pada file tersebut. Kalau nama itu sudah ada di daftar karakter aktif (tidak peduli huruf besar/kecil atau spasi), import ditolak dan tidak ada data yang digabung.
4. Kalau nama belum ada, aplikasi memecah data menjadi stage-stage (resource, insight, farming) dan menambahkannya ke daftar daily task.

Maksimal 4 karakter aktif dalam satu waktu. Karakter bisa dihapus sewaktu-waktu lewat menu Karakter.

### Urutan Kerja

Urutan antar kategori bersifat tetap: resource stages dulu, lalu insight stages, lalu farming stages, digabung lintas karakter. Urutan antar stage dalam satu kategori bisa diatur manual.

### Kategori Stage

- **Resource dan Insight**: drop rate pasti, ada progress bar material, stok bertambah otomatis saat stage dicentang.
- **Farming**: drop rate berupa expected value, hanya melacak jumlah run selesai, tidak ada progress bar material.

### Wilderness

Passive income harian (Dust dan Sharpodonty) yang berlaku global, bukan per karakter. Muncul di daftar daily task hanya kalau nilainya lebih dari 0, dan hilang dari daftar begitu sudah dicentang hari itu. Task lain baru dianggap selesai semua kalau Wilderness juga sudah dicentang.

### Edit Stok, Bonus, dan Reset

Perilakunya sama seperti Modul 1: Edit Stok untuk koreksi kapan saja, Bonus untuk reward tambahan setelah semua task selesai, Reset Hari Ini untuk membatalkan centang hari itu, Reset All untuk mengosongkan stok dan history.

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

- `lib/models/` — definisi Resource, Activity, Planner Config, History (Modul 1) dan StageTask, CharacterPlan, MaterialTarget (Modul 2)
- `lib/logic/daily_plan_v2.dart` — kalkulasi rencana harian Modul 1
- `lib/logic/character_daily_plan.dart` — kalkulasi rencana harian Modul 2
- `lib/logic/character_plan_parser.dart` — parsing hasil solver dan penggabungan karakter baru ke state
- `lib/providers/app_provider_v2.dart` — state management Modul 1
- `lib/providers/character_upgrade_provider.dart` — state management Modul 2, termasuk validasi nama karakter duplikat saat import

## Lisensi

MIT LICENSE
