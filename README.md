# NutriLensia (Mobile)

Aplikasi Flutter buat baca label gizi kemasan dan taksir gizi makanan dari foto. Cekrek, langsung tahu Nutri-Score, gula, natrium, dan kawan-kawannya.

Backend-nya ada di repo `Backend-Ceklabel` (`https://ceklabel-api.vercel.app`).

## Fitur

- Scan tabel gizi kemasan, langsung dapat Nutri-Score + penjelasan.
- Foto makanan jadi juga bisa, AI yang pilah otomatis mau jalur label atau estimasi.
- Asisten Gizi: tanya jawab soal nutrisi, nyambung ke riwayat scan dan diary kamu.
- Lanjut di Telegram: tautkan akun sekali, terus chat bot-nya tanpa buka aplikasi.
- Diary harian, laporan mingguan (bisa export PDF), profil keluarga + alergi.
- Prediksi risiko kesehatan dari pola 30 hari, kuis nutrisi, bandingkan produk.

## Jalanin lokal

Butuh Flutter SDK (lihat versi di `pubspec.yaml`).

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Build rilis:

```bash
flutter build apk --release
```

## Struktur folder

```text
lib/
├── screens/     Layar utama (scanner, hasil, riwayat, profil, dll)
├── widgets/     Komponen dipakai ulang
├── services/    API (Dio), auth, history
├── models/      Model data
├── theme/       Warna, grade Nutri-Score
└── providers/   State global (misal mode tema)
```

Aturan main:

- Warna grade selalu lewat `gradeColor()` di `lib/theme/grade_colors.dart`, jangan hardcode di layar.
- Cek `mounted` sebelum `setState` di kode async.
- Tambah endpoint? Ikuti pola di `lib/services/api_service.dart` (Dio + `ApiException`).

## Kontribusi

Bikin branch dari `main`, buka PR ke `main`. CI jalanin `analyze` + `test`, pastikan hijau sebelum merge.
