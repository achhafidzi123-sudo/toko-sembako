# Aplikasi Toko Sembako

Aplikasi mobile (Android & iOS) untuk mengelola toko sembako: kasir, stok barang,
belanja ke pemasok/pabrik, dan laporan penjualan. Dibuat dengan **Flutter** +
**Supabase** (database cloud, bisa diakses dari beberapa HP sekaligus).

Created by **Afi Hafidzi**.

---

## Fitur

- **Kasir** — cari barang, tambah ke keranjang, bayar (tunai/QRIS/kasbon), stok otomatis berkurang.
- **Stok & Barang** — tambah barang manual, edit nama/harga/stok, hapus (nonaktifkan), dan **import massal dari Excel** (dengan template siap pakai).
- **Belanja ke Pemasok** — catat pembelian barang dari pabrik/agen; stok otomatis bertambah dan harga modal ter-update.
- **Laporan** — ringkasan omzet 7 hari / 30 hari / bulan ini, grafik batang, rincian per hari.
- **Beranda** — ringkasan harian & peringatan stok menipis.

Data awal toko kamu (175 produk dari daftar harga yang diberikan) sudah disiapkan di
`data/template_import_barang.csv` — tinggal dikonversi ke `.xlsx` dan di-import lewat
aplikasi (lihat langkah 4 di bawah), atau dimasukkan manual lewat SQL (langkah 3).

---

## 1. Setup Supabase (database cloud, gratis untuk mulai)

1. Buka [supabase.com](https://supabase.com) → **New project**. Catat *nama project* dan *password database*.
2. Setelah project jadi, buka menu **SQL Editor** → **New query**.
3. Buka file `supabase/schema.sql` di folder ini, salin seluruh isinya, tempel ke SQL Editor, lalu klik **Run**.
   Ini akan membuat semua tabel (produk, transaksi, pembelian, dll) sekaligus kategori awal.
4. Buka menu **Project Settings → API**. Catat dua nilai ini:
   - **Project URL** (contoh: `https://xxxxx.supabase.co`)
   - **anon public key** (kunci panjang berawalan `eyJ...`)
5. Buka menu **Authentication → Providers**, pastikan **Email** aktif (biasanya sudah aktif secara default).
   Jika ingin langsung bisa login tanpa verifikasi email, matikan "Confirm email" di
   **Authentication → Settings**.

## 2. Hubungkan aplikasi Flutter ke Supabase

Buka file `lib/main.dart`, ganti dua baris ini dengan nilai dari langkah 1.4 di atas:

```dart
const String supabaseUrl = 'ISI_URL_SUPABASE_KAMU';
const String supabaseAnonKey = 'ISI_ANON_KEY_SUPABASE_KAMU';
```

## 3. (Opsional) Masukkan data barang awal lewat SQL langsung

Jika ingin memasukkan 175 barang dari daftar harga toko langsung tanpa lewat fitur
import di aplikasi: buka `data/template_import_barang.csv`, lalu di Supabase buka
**Table Editor → products → Insert → Import data from CSV**, dan sesuaikan nama kolom
(`nama_barang`, `harga_modal`, `harga_jual`, `harga_pack`, `stok`). Kolom `kategori`
di CSV tersebut hanya referensi — kategori asli ada di tabel `categories`, bisa
dihubungkan manual jika perlu.

## 4. Cara pakai fitur Import Excel di aplikasi

1. Buka menu **Stok** → tombol **Tambah Barang** → **Download Template Excel**.
   File `template_import_barang.xlsx` akan terbuka di menu share HP — simpan ke Google Drive/HP.
2. Buka file itu, isi baris-baris barang (kolom: `nama_barang`, `satuan`, `harga_modal`, `harga_jual`, `harga_pack`, `stok`).
   Boleh hapus baris contoh, boleh kosongkan `harga_pack` jika tidak ada harga grosir.
3. Kembali ke aplikasi → **Tambah Barang** → **Import dari Excel** → pilih file yang sudah diisi.
4. Barang dengan nama yang sama seperti yang sudah ada akan **diperbarui harganya**;
   barang baru akan **ditambahkan**.

## 5. Dapatkan file APK GRATIS tanpa install apapun (pakai GitHub Actions)

Cara ini paling mudah kalau kamu tidak punya laptop untuk coding — GitHub yang akan
"build" APK-nya untukmu secara gratis. Workflow-nya (`.github/workflows/build-apk.yml`)
sudah disiapkan di project ini.

1. Buat akun gratis di [github.com](https://github.com) kalau belum punya.
2. Buat repository baru (tombol **New repository**), beri nama misal `toko-sembako`, set **Private** atau **Public** (bebas), jangan centang "Add README" (kita sudah punya).
3. Di komputer manapun yang ada akses internet & git (atau pakai fitur "upload file" langsung di web GitHub kalau tidak punya git), upload **seluruh isi folder** `toko-sembako` hasil ekstrak zip ini ke repository tadi.
   - Cara termudah tanpa command line: buka repo di GitHub → **Add file → Upload files** → drag semua file & folder (termasuk folder `.github`, `lib`, dll) → **Commit changes**.
4. Masuk ke tab **Actions** di repository tersebut. Build akan otomatis berjalan (ditandai titik kuning berputar → lalu centang hijau kalau sukses, biasanya 5-10 menit).
   - Kalau tidak jalan otomatis, klik workflow **Build APK** → **Run workflow**.
5. Setelah selesai (centang hijau), klik hasil build tersebut → scroll ke bagian **Artifacts** → download **toko-sembako-apk** (berupa file .zip berisi `app-release.apk`).
6. Ekstrak zip-nya, pindahkan `app-release.apk` ke HP Android (lewat kabel data, WhatsApp ke diri sendiri, Google Drive, dll), lalu buka file itu di HP untuk menginstall.
   - HP mungkin akan menampilkan peringatan "sumber tidak dikenal" — ini normal untuk APK yang tidak dari Play Store, tinggal izinkan instalasi.

Catatan: **jangan upload kredensial Supabase asli ke repository Public** kalau repo-nya terbuka untuk umum — gunakan **Private** repository agar lebih aman, karena file `lib/main.dart` berisi API key project kamu.

## 6. Alternatif: build APK di laptop sendiri

Kalau punya laptop dan ingin build manual, pasang [Flutter SDK](https://docs.flutter.dev/get-started/install) dan Android Studio, lalu:

```bash
cd toko-sembako
flutter pub get
flutter build apk --release
```

File APK akan muncul di `build/app/outputs/flutter-apk/app-release.apk`. Untuk mencoba
langsung tanpa build APK dulu, bisa juga pakai `flutter run` saat HP tersambung ke laptop.

---

## Struktur Project

```
lib/
  main.dart                     # entry point + koneksi Supabase
  theme/app_theme.dart          # warna, font, gaya tombol (desain user-friendly)
  models/                       # Product, Supplier, CartItem
  services/
    supabase_service.dart       # semua query ke database
    excel_import_service.dart   # buat template & baca file Excel
  screens/
    login_screen.dart
    home_screen.dart             # shell + bottom navigation
    beranda_screen.dart          # dashboard ringkasan
    kasir_screen.dart            # POS / kasir
    produk_screen.dart           # daftar barang + tambah/import
    tambah_edit_produk_screen.dart
    pembelian_screen.dart        # belanja ke pemasok/pabrik
    laporan_screen.dart          # grafik & ringkasan penjualan
supabase/
  schema.sql                     # seluruh skema database + trigger stok otomatis
data/
  template_import_barang.csv     # 175 barang hasil parsing daftar harga toko
```

## Catatan Pengembangan Lanjutan (belum termasuk di versi ini)

- Laporan laba-rugi detail per item (saat ini baru omzet, belum dikurangi modal per transaksi).
- Manajemen hak akses owner vs kasir (kolom `role` di tabel `profiles` sudah ada, tinggal diterapkan di UI).
- Cetak struk ke printer thermal bluetooth.
- Riwayat & pelunasan kasbon/piutang pelanggan.
