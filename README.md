# NutriLensia (Mobile)

Aplikasi Flutter buat baca label gizi kemasan dan taksir gizi makanan dari foto. Cekrek, langsung tahu Nutri-Score, gula, natrium, dan kawan-kawannya.

## Fitur

- Scan tabel gizi kemasan, langsung dapat Nutri-Score + penjelasan.
- Foto makanan jadi juga bisa, AI yang pilah otomatis mau jalur label atau estimasi.
- Asisten Gizi: tanya jawab soal nutrisi, nyambung ke riwayat scan dan diary kamu.
- Lanjut di Telegram: tautkan akun sekali, terus chat bot-nya tanpa buka aplikasi.
- Diary harian, laporan mingguan (bisa export PDF), profil keluarga + alergi.
- Prediksi risiko kesehatan dari pola 30 hari, kuis nutrisi, bandingkan produk.

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
