# ThriftIn (versi sederhana)

Aplikasi marketplace barang thrift untuk tugas Pengembangan Aplikasi Bergerak (Flutter).
Satu halaman = satu file. Tanpa Provider, tanpa JSON. Data disimpan di memori.

## Cara menjalankan

1. Buat proyek Flutter baru: `flutter create thrift_app`
2. Hapus folder `lib/` bawaan, lalu salin folder `lib/` dan file `pubspec.yaml` dari zip ini (timpa).
3. Hapus file `test/widget_test.dart` (bawaan Flutter, akan error karena nama class berbeda).
4. Jalankan `flutter pub get`, lalu `flutter run`.

Izin foto (image_picker):
- Android: biasanya tanpa pengaturan tambahan.
- iOS: tambahkan `NSPhotoLibraryUsageDescription` dan `NSCameraUsageDescription` di `ios/Runner/Info.plist`.
-

## Akun demo (password semuanya 123456)

| Akun | Yang bisa dicoba |
|---|---|
| rina@mail.com | Ada 1 tawaran masuk (terima/tolak/counter), 1 pesanan dibayar (proses, kirim), saldo Rp 150.000 untuk withdraw |
| dimas@mail.com | Membeli barang Rina, menawar, chat |
| salsa@mail.com | Kota Jakarta (COD tidak tersedia ke penjual Yogyakarta) |

Skenario demo: masuk sebagai Dimas, tawar Jaket Denim, keluar, masuk sebagai Rina, counter, keluar,
masuk sebagai Dimas, terima counter, checkout, lalu proses sampai selesai dengan bergantian akun.

## Peta file (urutan belajar yang disarankan)

| Urutan | File | Isi | Konsep utama |
|---|---|---|---|
| 1 | main.dart | Titik awal, tema | runApp, MaterialApp, ThemeData |
| 2 | login_page.dart, register_page.dart | Masuk dan daftar | StatefulWidget, setState, Form |
| 3 | main_page.dart | 5 menu bawah | NavigationBar, Badge |
| 4 | home_page.dart, product_card.dart | Jelajah, cari, filter | GridView, ChoiceChip, BottomSheet |
| 5 | product_detail_page.dart, shop_page.dart | Detail barang, lapak | ListView, Navigator, dialog |
| 6 | sell_page.dart, my_products_page.dart | Jual dan kelola barang | Form, Dropdown, image_picker |
| 7 | wishlist_page.dart, profile_page.dart, address_page.dart | Favorit, profil, alamat | ListTile, CRUD |
| 8 | checkout_page.dart, order_detail_page.dart, activity_page.dart | Checkout, pesanan, tawaran | SegmentedButton, alur status |
| 9 | wallet_page.dart, withdraw_page.dart | Saldo dan penarikan | validasi berlapis |
| 10 | chat_list_page.dart, chat_page.dart | Pesan | ListView.builder, ScrollController |
| Pendukung | models.dart, data_store.dart, helpers.dart | Data, logika, fungsi bantu | class, List, fungsi |

## Yang disederhanakan dibanding versi asli

- Data tidak permanen: kembali ke data contoh setiap aplikasi ditutup.
- Tidak ada pembatalan otomatis berdasarkan waktu (tidak ada Timer).
- Pembayaran dan penarikan hanya simulasi; penarikan langsung berhasil.
- Status pesanan diubah lewat tombol, bukan otomatis.
