import 'package:flutter/material.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'sell_page.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  Future<void> _openSellPage([Product? product]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellPage(product: product)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(Product p) async {
    if (hasActiveOrderFor(p.id)) {
      showSnack(
        context,
        'Barang masih punya pesanan berjalan, belum bisa dihapus',
      );
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Hapus barang',
      message: 'Hapus "${p.title}"? Tindakan ini tidak bisa dibatalkan.',
      confirmText: 'Hapus',
    );
    if (!ok) return;
    deleteProduct(p.id);
    if (mounted) setState(() {});
  }

  void _onMenu(String action, Product p) {
    if (action == 'edit') {
      _openSellPage(p);
    } else if (action == 'sold') {
      setSold(p, true);
      setState(() {});
    } else if (action == 'relist') {
      setSold(p, false);
      setState(() {});
    } else if (action == 'delete') {
      _delete(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final items = productsBySeller(me.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Barang saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSellPage(),
        icon: const Icon(Icons.add),
        label: const Text('Jual barang'),
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.sell_outlined,
              message:
                  'Kamu belum menjual apa pun.\nTekan "Jual barang" untuk mulai.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = items[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ProductImage(
                          path: p.imagePath,
                          category: p.category,
                        ),
                      ),
                    ),
                    title: Text(p.title, maxLines: 1),
                    subtitle: Text(
                      '${formatRupiah(p.price)}\n'
                      '${p.isSold ? "TERJUAL / HABIS" : "Stok: ${p.stock}"}',
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(productId: p.id),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => _onMenu(action, p),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (p.isSold)
                          const PopupMenuItem(
                            value: 'relist',
                            child: Text('Jual kembali'),
                          )
                        else
                          const PopupMenuItem(
                            value: 'sold',
                            child: Text('Tandai terjual'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
