// ============================================================
// activity_page.dart  -  Tab "Aktivitas": tawaran & pesanan
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - DefaultTabController + TabBar + TabBarView (dua tab)
//  - menampilkan dua jenis data dalam satu daftar
//  - tombol yang berubah menurut status (alur tawar-menawar)
// ============================================================

import 'package:flutter/material.dart';

import 'checkout_page.dart';
import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';
import 'order_detail_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  // ---------------- AKSI TAWARAN ----------------

  void _accept(Offer o) {
    respondOffer(o, OfferStatus.accepted);
    setState(() {});
    showSnack(context, 'Tawaran disetujui. Pembeli bisa lanjut checkout.');
  }

  void _reject(Offer o) {
    respondOffer(o, OfferStatus.rejected);
    setState(() {});
  }

  Future<void> _counter(Offer o) async {
    final text = await askTextDialog(
      context,
      title: 'Balas dengan harga lain',
      label: 'Harga counter per barang (Rp)',
      numberOnly: true,
    );
    if (text == null) return;
    if (!mounted) return;

    final price = int.tryParse(text);
    final product = productById(o.productId);
    if (price == null || price <= o.price) {
      showSnack(context, 'Harga counter harus lebih tinggi dari tawaran');
      return;
    }
    if (product != null && price > product.price) {
      showSnack(context, 'Harga counter tidak boleh melebihi harga barang');
      return;
    }
    respondOffer(o, OfferStatus.countered, newPrice: price);
    setState(() {});
  }

  Future<void> _checkoutOffer(Offer o) async {
    final product = productById(o.productId);
    if (product == null || product.stock < o.quantity) {
      showSnack(context, 'Maaf, barang sudah tidak tersedia / stok kurang');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          product: product,
          quantity: o.quantity,
          unitPrice: o.price,
          offer: o,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  // ---------------- TAMPILAN ----------------

  Widget _offerTile(Offer o, bool asBuyer) {
    final other = userById(asBuyer ? o.sellerId : o.buyerId);
    final buttons = <Widget>[];

    if (!asBuyer && o.status == OfferStatus.waiting) {
      buttons.addAll([
        FilledButton(onPressed: () => _accept(o), child: const Text('Terima')),
        OutlinedButton(
          onPressed: () => _counter(o),
          child: const Text('Counter'),
        ),
        OutlinedButton(
          onPressed: () => _reject(o),
          child: const Text('Tolak'),
        ),
      ]);
    }
    if (asBuyer && o.status == OfferStatus.countered) {
      buttons.addAll([
        FilledButton(
          onPressed: () => _accept(o),
          child: const Text('Terima counter'),
        ),
        OutlinedButton(
          onPressed: () => _reject(o),
          child: const Text('Tolak'),
        ),
      ]);
    }
    if (asBuyer && o.status == OfferStatus.accepted) {
      buttons.add(FilledButton(
        onPressed: () => _checkoutOffer(o),
        child: const Text('Lanjut checkout'),
      ));
    }

    String info = '';
    if (o.status == OfferStatus.waiting) {
      info = asBuyer
          ? 'Menunggu jawaban penjual'
          : 'Tawaran masuk, mohon direspons';
    } else if (o.status == OfferStatus.countered) {
      info = asBuyer
          ? 'Penjual membalas dengan harga lain'
          : 'Menunggu jawaban pembeli';
    } else if (o.status == OfferStatus.accepted) {
      info = asBuyer
          ? 'Disetujui! Silakan checkout'
          : 'Menunggu pembeli checkout';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    o.productTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusChip(
                  label: offerStatusLabel(o.status),
                  color: offerStatusColor(o.status),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${asBuyer ? "Penjual" : "Pembeli"}: ${other?.name ?? "-"}'),
            Text('Harga tawaran: ${formatRupiah(o.price)} x ${o.quantity}'),
            if (info.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  info,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            if (buttons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: buttons),
            ],
          ],
        ),
      ),
    );
  }

  Widget _orderTile(Order o, bool asBuyer) {
    final other = userById(asBuyer ? o.sellerId : o.buyerId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id)),
          );
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    o.isCourier
                        ? Icons.local_shipping_outlined
                        : Icons.people_outline,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      o.productTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusChip(
                    label: orderStatusLabel(o.status),
                    color: orderStatusColor(o.status),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${asBuyer ? "Penjual" : "Pembeli"}: ${other?.name ?? "-"}'),
              Text(
                '${o.isCourier ? "Kurir" : "COD"} • Total ${formatRupiah(o.total)}',
              ),
              Text(
                formatDateTime(o.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({required bool asBuyer}) {
    final me = currentUser!;
    final offerList = asBuyer ? offersAsBuyer(me.id) : offersAsSeller(me.id);
    final orderList = asBuyer ? purchasesOf(me.id) : salesOf(me.id);

    if (offerList.isEmpty && orderList.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: asBuyer
            ? 'Belum ada pembelian atau tawaran.'
            : 'Belum ada penjualan atau tawaran masuk.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (offerList.isNotEmpty) ...[
          const Text(
            'Tawaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          for (final o in offerList) _offerTile(o, asBuyer),
        ],
        if (orderList.isNotEmpty) ...[
          const Text(
            'Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          for (final o in orderList) _orderTile(o, asBuyer),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Aktivitas'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Pembelian'), Tab(text: 'Penjualan')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTab(asBuyer: true),
            _buildTab(asBuyer: false),
          ],
        ),
      ),
    );
  }
}
