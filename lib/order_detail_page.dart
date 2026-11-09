// ============================================================
// order_detail_page.dart  -  Detail & proses pesanan
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - menampilkan data yang sama dengan tombol berbeda untuk
//    pembeli dan penjual (if isBuyer / isSeller)
//  - alur status pesanan (menunggu bayar -> dibayar -> ... -> selesai)
//  - fungsi pembantu yang mengembalikan Widget (_infoRow, _card)
// ============================================================

import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _costRow(String label, int value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatRupiah(value), style: style),
        ],
      ),
    );
  }

  /// Urutan langkah sesuai jalur transaksi.
  List<String> _steps(Order o) {
    if (o.isCourier) {
      return [
        OrderStatus.awaitingPayment,
        OrderStatus.paid,
        OrderStatus.packed,
        OrderStatus.shipped,
        OrderStatus.done,
      ];
    }
    return [
      OrderStatus.awaitingMeetup,
      OrderStatus.meetupApproved,
      OrderStatus.done,
    ];
  }

  Widget _progress(Order o) {
    final steps = _steps(o);
    final current = steps.indexOf(o.status); // -1 jika dibatalkan
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  i <= current ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: i <= current ? scheme.primary : Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  orderStatusLabel(steps[i]),
                  style: TextStyle(
                    fontWeight:
                        i == current ? FontWeight.bold : FontWeight.normal,
                    color: i <= current ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------- AKSI ----------------

  Future<void> _cancel(Order o) async {
    final me = currentUser!;
    final reason = await askTextDialog(
      context,
      title: 'Batalkan pesanan',
      label: 'Alasan pembatalan',
    );
    if (reason == null) return; // user menekan Batal
    cancelOrder(o, me.id, reason.isEmpty ? 'Tanpa alasan' : reason);
    if (!mounted) return;
    setState(() {});
    showSnack(context, 'Pesanan dibatalkan, stok dikembalikan');
  }

  Future<void> _confirmReceived(Order o) async {
    final ok = await confirmDialog(
      context,
      title: 'Konfirmasi barang diterima',
      message: o.isCourier
          ? 'Dana akan diteruskan ke saldo penjual. Lanjutkan?'
          : 'Pastikan kamu sudah bertemu dan membayar tunai. Lanjutkan?',
      confirmText: 'Konfirmasi',
    );
    if (!ok) return;
    completeOrder(o);
    if (!mounted) return;
    setState(() {});
    showSnack(context, 'Pesanan selesai');
  }

  List<Widget> _buildActions(Order o, bool isBuyer, bool isSeller) {
    final actions = <Widget>[];

    if (o.isCourier) {
      if (o.status == OrderStatus.awaitingPayment && isBuyer) {
        actions.add(FilledButton(
          onPressed: () {
            payOrder(o);
            setState(() {});
            showSnack(context, 'Pembayaran berhasil (simulasi)');
          },
          child: Text('Bayar sekarang • ${formatRupiah(o.total)}'),
        ));
      }
      if (o.status == OrderStatus.paid && isSeller) {
        actions.add(FilledButton(
          onPressed: () {
            packOrder(o);
            setState(() {});
          },
          child: const Text('Proses pesanan (kemas barang)'),
        ));
      }
      if (o.status == OrderStatus.packed && isSeller) {
        actions.add(FilledButton(
          onPressed: () {
            shipOrder(o);
            setState(() {});
            showSnack(context, 'Barang dikirim, nomor resi dibuat');
          },
          child: const Text('Kirim barang (buat resi)'),
        ));
      }
      if (o.status == OrderStatus.shipped && isBuyer) {
        actions.add(FilledButton(
          onPressed: () => _confirmReceived(o),
          child: const Text('Konfirmasi barang diterima'),
        ));
      }
    } else {
      if (o.status == OrderStatus.awaitingMeetup && isSeller) {
        actions.add(FilledButton(
          onPressed: () {
            approveMeetup(o);
            setState(() {});
          },
          child: const Text('Setujui jadwal bertemu'),
        ));
      }
      if (o.status == OrderStatus.meetupApproved && isBuyer) {
        actions.add(FilledButton(
          onPressed: () => _confirmReceived(o),
          child: const Text('Sudah bertemu & bayar tunai'),
        ));
      }
    }

    if (o.canCancel) {
      actions.add(OutlinedButton(
        onPressed: () => _cancel(o),
        child: const Text('Batalkan pesanan'),
      ));
    }

    // Beri jarak antar tombol.
    final spaced = <Widget>[];
    for (final a in actions) {
      spaced.add(SizedBox(width: double.infinity, child: a));
      spaced.add(const SizedBox(height: 8));
    }
    return spaced;
  }

  @override
  Widget build(BuildContext context) {
    final o = orderById(widget.orderId);
    if (o == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.receipt_long,
          message: 'Pesanan tidak ditemukan.',
        ),
      );
    }

    final me = currentUser!;
    final isBuyer = o.buyerId == me.id;
    final isSeller = o.sellerId == me.id;
    final other = userById(isBuyer ? o.sellerId : o.buyerId);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Status ----
          _card('Status pesanan', [
            Row(
              children: [
                StatusChip(
                  label: orderStatusLabel(o.status),
                  color: orderStatusColor(o.status),
                ),
                const Spacer(),
                Text(
                  formatDateTime(o.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (o.status == OrderStatus.cancelled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dibatalkan oleh ${userById(o.cancelledBy)?.name ?? "-"}.\n'
                  'Alasan: ${o.cancelReason}',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              )
            else
              _progress(o),
          ]),
          // ---- Barang ----
          _card('Barang', [
            Text(
              o.productTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('${formatRupiah(o.unitPrice)} x ${o.quantity}'),
          ]),
          // ---- Lawan transaksi ----
          if (other != null)
            _card(isBuyer ? 'Penjual' : 'Pembeli', [
              Row(
                children: [
                  CircleAvatar(child: Text(initialOf(other.name))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(other.name)),
                  IconButton(
                    tooltip: 'Chat',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(otherUserId: other.id),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          // ---- Info pengiriman / pertemuan ----
          if (o.isCourier)
            _card('Pengiriman & pembayaran', [
              _infoRow('Kurir', o.courier),
              _infoRow('Alamat', o.addressText),
              _infoRow('Pembayaran', o.paymentMethod),
              _infoRow(
                'Kode bayar',
                o.paymentCode,
              ),
              if (o.resi.isNotEmpty) _infoRow('No. resi', o.resi),
            ])
          else
            _card('Pertemuan (COD)', [
              _infoRow('Titik temu', o.meetupPlace),
              _infoRow('Waktu', o.meetupTime),
              const SizedBox(height: 4),
              const Text(
                'Bayar tunai saat bertemu. Uang tidak masuk saldo.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ]),
          // ---- Biaya ----
          _card('Rincian biaya', [
            _costRow('Subtotal', o.subtotal),
            if (o.isCourier) _costRow('Ongkos kirim', o.shippingCost),
            const Divider(),
            _costRow('Total', o.total, bold: true),
          ]),
          // ---- Tombol aksi ----
          ..._buildActions(o, isBuyer, isSeller),
        ],
      ),
    );
  }
}
