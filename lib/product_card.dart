// ============================================================
// product_card.dart  -  Kartu barang (dipakai di Jelajah, Favorit, Lapak)
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - widget yang dipakai ulang di banyak halaman
//  - Card, InkWell (bisa diklik), Stack (tumpuk widget)
//  - callback (onChanged) agar halaman induk ikut diperbarui
// ============================================================

import 'package:flutter/material.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';
import 'product_detail_page.dart';

/// Pengaturan grid 2 kolom yang dipakai semua halaman yang menampilkan barang.
const productGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  childAspectRatio: 0.68,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
);

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, this.onChanged});

  final Product product;

  /// Dipanggil saat ada perubahan (favorit / kembali dari detail),
  /// supaya halaman induk bisa menggambar ulang.
  final VoidCallback? onChanged;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Future<void> _openDetail() async {
    final p = widget.product;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(productId: p.id)),
    );
    widget.onChanged?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final me = currentUser;
    final mine = me != null && p.sellerId == me.id;
    final wished = isWishlisted(p.id);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(path: p.imagePath, category: p.category),
                  if (p.isSold)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text(
                        'TERJUAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  if (mine)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Milikmu',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        toggleWishlist(p.id);
                        setState(() {});
                        widget.onChanged?.call();
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black38,
                        child: Icon(
                          wished ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: wished ? Colors.redAccent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(p.price),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.size} • ${p.condition}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
