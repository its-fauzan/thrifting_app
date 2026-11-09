// ============================================================
// product_detail_page.dart  -  Detail barang
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - ListView berisi banyak bagian (gambar, info, penjual)
//  - bottomNavigationBar untuk tombol Beli / Tawar
//  - showDialog + StatefulBuilder (dialog yang punya state sendiri)
//  - kirim data ke halaman lain lewat constructor
// ============================================================

import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'checkout_page.dart';
import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';
import 'sell_page.dart';
import 'shop_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1; // jumlah yang mau dibeli

  Future<void> _buyNow(Product p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          product: p,
          quantity: _qty,
          unitPrice: p.price,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _makeOffer(Product p) async {
    final me = currentUser!;
    if (activeOfferOf(me.id, p.id) != null) {
      showSnack(context,
          'Kamu masih punya tawaran aktif untuk barang ini. Cek tab Aktivitas.');
      return;
    }

    final priceCtrl = TextEditingController();
    String? error; // pesan error di dalam dialog

    final price = await showDialog<int>(
      context: context,
      builder: (ctx) {
        // StatefulBuilder membuat dialog bisa memanggil setState sendiri.
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Ajukan tawaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Harga: ${formatRupiah(p.price)}  •  Jumlah: $_qty'),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tawaranmu per barang',
                    prefixText: 'Rp ',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(priceCtrl.text.trim());
                  if (value == null || value <= 0) {
                    setLocal(() => error = 'Masukkan angka yang valid');
                  } else if (value >= p.price) {
                    setLocal(
                        () => error = 'Tawaran harus lebih rendah dari harga');
                  } else {
                    Navigator.pop(ctx, value);
                  }
                },
                child: const Text('Kirim'),
              ),
            ],
          ),
        );
      },
    );

    if (price == null) return;
    createOffer(product: p, buyer: me, price: price, quantity: _qty);
    if (!mounted) return;
    showSnack(context, 'Tawaran terkirim. Pantau di tab Aktivitas.');
  }

  @override
  Widget build(BuildContext context) {
    final p = productById(widget.productId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          message: 'Barang tidak ditemukan.',
        ),
      );
    }

    final me = currentUser!;
    final seller = userById(p.sellerId);
    final mine = p.sellerId == me.id;
    final wished = isWishlisted(p.id);
    final scheme = Theme.of(context).colorScheme;
    if (p.stock > 0 && _qty > p.stock) _qty = p.stock;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail barang'),
        actions: [
          IconButton(
            icon: Icon(
              wished ? Icons.favorite : Icons.favorite_border,
              color: wished ? Colors.red : null,
            ),
            onPressed: () => setState(() => toggleWishlist(p.id)),
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 300,
            child: ProductImage(path: p.imagePath, category: p.category),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(p.price),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(p.category)),
                    Chip(label: Text('Ukuran ${p.size}')),
                    Chip(label: Text(p.condition)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.isSold ? 'Stok habis' : 'Stok tersedia: ${p.stock}',
                  style: TextStyle(
                    color: p.isSold ? Colors.red : Colors.grey,
                  ),
                ),
                // Catatan cacat hanya muncul jika kondisi "Ada Minus".
                if (p.condition == 'Ada Minus' &&
                    p.conditionNote.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Catatan minus: ${p.conditionNote}',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(p.description.isEmpty ? '-' : p.description),
                const SizedBox(height: 16),
                // ---- Kartu penjual ----
                if (seller != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(initialOf(seller.name))),
                      title: Text(seller.name),
                      subtitle: Text(
                        cityOf(seller.id) ?? 'Lokasi belum diatur',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopPage(userId: seller.id),
                        ),
                      ),
                      trailing: mine
                          ? null
                          : IconButton(
                              tooltip: 'Chat penjual',
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    otherUserId: seller.id,
                                    productId: p.id,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                // ---- Pilih jumlah (hanya jika stok lebih dari 1) ----
                if (!mine && p.stock > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Jumlah'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            _qty > 1 ? () => setState(() => _qty--) : null,
                      ),
                      Text('$_qty', style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _qty < p.stock
                            ? () => setState(() => _qty++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: mine
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit barang ini'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SellPage(product: p)),
                    );
                    if (mounted) setState(() {});
                  },
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: p.isSold ? null : () => _makeOffer(p),
                        child: const Text('Tawar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: p.isSold ? null : () => _buyNow(p),
                        child: Text(p.isSold ? 'Stok habis' : 'Beli langsung'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
