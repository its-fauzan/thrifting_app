// ============================================================
// wishlist_page.dart  -  Tab "Favorit"
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - mengubah daftar id menjadi daftar barang (map + whereType)
//  - memakai ulang ProductCard
// ============================================================

import 'package:flutter/material.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';
import 'product_card.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    // Ubah daftar id menjadi daftar barang. Barang yang sudah dihapus dilewati.
    final items = me.wishlist.map(productById).whereType<Product>().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorit')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              message: 'Belum ada barang favorit.\nTekan ikon hati pada barang.',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: productGridDelegate,
              itemCount: items.length,
              itemBuilder: (context, i) => ProductCard(
                product: items[i],
                onChanged: () => setState(() {}),
              ),
            ),
    );
  }
}
