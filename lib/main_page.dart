// ============================================================
// main_page.dart  -  Kerangka utama dengan 5 menu di bawah
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - NavigationBar (menu bawah) + Badge (angka merah)
//  - memilih halaman berdasarkan nomor tab (_index)
//  - ValueListenableBuilder: menggambar ulang saat data berubah
// ============================================================

import 'package:flutter/material.dart';

import 'activity_page.dart';
import 'data_store.dart';
import 'home_page.dart';
import 'my_products_page.dart';
import 'profile_page.dart';
import 'wishlist_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0; // tab yang sedang dipilih

  /// Halaman dibuat ulang tiap pindah tab, supaya datanya selalu terbaru.
  Widget _currentPage() {
    switch (_index) {
      case 0:
        return const HomePage();
      case 1:
        return const MyProductsPage();
      case 2:
        return const ActivityPage();
      case 3:
        return const WishlistPage();
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage(),
      // ValueListenableBuilder dipanggil ulang tiap dataVersion berubah,
      // jadi angka badge selalu mengikuti data terbaru.
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: dataVersion,
        builder: (context, _, __) {
          final me = currentUser;
          final pending = me == null ? 0 : actionCount(me.id);

          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Jelajah',
              ),
              const NavigationDestination(
                icon: Icon(Icons.sell_outlined),
                selectedIcon: Icon(Icons.sell),
                label: 'Jual',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending'),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending'),
                  child: const Icon(Icons.receipt_long),
                ),
                label: 'Aktivitas',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favorit',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
