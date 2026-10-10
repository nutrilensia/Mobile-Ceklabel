# NutriLensia (Mobile)

[![Flutter Test](https://github.com/nutrilensia/Mobile-Ceklabel/actions/workflows/flutter-test.yml/badge.svg)](https://github.com/nutrilensia/Mobile-Ceklabel/actions/workflows/flutter-test.yml)
[![Flutter Release Build](https://github.com/nutrilensia/Mobile-Ceklabel/actions/workflows/main.yml/badge.svg)](https://github.com/nutrilensia/Mobile-Ceklabel/actions/workflows/main.yml)

Aplikasi Flutter buat baca label gizi kemasan dan taksir gizi makanan dari foto. Cekrek, langsung tahu Nutri-Score, gula, natrium, dan kawan-kawannya.

## Fitur

- Scan tabel gizi kemasan, langsung dapat Nutri-Score + penjelasan.
- Foto makanan jadi juga bisa, AI yang pilah otomatis mau jalur label atau estimasi.
- Asisten Gizi: tanya jawab soal nutrisi, nyambung ke riwayat scan dan diary kamu.
- Lanjut di Telegram: tautkan akun sekali, terus chat bot-nya tanpa buka aplikasi.
- Diary harian, laporan mingguan (bisa export PDF), profil keluarga + alergi.
- Prediksi risiko kesehatan dari pola 30 hari, kuis nutrisi, bandingkan produk.

## Quick Start

Butuh Flutter channel stable dengan Dart `^3.12.1` (cek `pubspec.yaml` kalau ragu).

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
