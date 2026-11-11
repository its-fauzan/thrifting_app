import 'package:flutter/material.dart';

import 'address_page.dart';
import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';
import 'order_detail_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.offer,
  });

  final Product product;
  final int quantity;
  final int unitPrice; // harga per barang (bisa hasil tawaran)
  final Offer? offer; // diisi jika checkout berasal dari tawaran

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _method = 'kurir'; // 'kurir' atau 'cod'
  String _courier = couriers.keys.first;
  String? _payment; // nama bank / e-wallet
  String? _addressId;
  final _placeCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressId = currentUser!.defaultAddress?.id;
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  bool _sameCity(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  Address? _selectedAddress(User me) {
    for (final a in me.addresses) {
      if (a.id == _addressId) return a;
    }
    return null;
  }

  Future<void> _openAddressPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressPage()),
    );
    if (!mounted) return;
    final me = currentUser!;
    setState(() {
      // Jika alamat yang dipilih sudah dihapus, pakai alamat utama.
      if (_selectedAddress(me) == null) {
        _addressId = me.defaultAddress?.id;
      }
    });
  }

  void _submit() {
    final me = currentUser!;
    final p = widget.product;
    final seller = userById(p.sellerId)!;

    if (p.stock < widget.quantity) {
      showSnack(context, 'Stok tidak cukup. Sisa stok: ${p.stock}');
      return;
    }

    final Order order;
    if (_method == 'kurir') {
      final address = _selectedAddress(me);
      if (address == null) {
        showSnack(context, 'Pilih atau tambah alamat pengiriman dulu');
        return;
      }
      if (_payment == null) {
        showSnack(context, 'Pilih metode pembayaran dulu');
        return;
      }
      final fee = shippingCost(
        _courier,
        _sameCity(address.city, cityOf(seller.id)),
        widget.quantity,
      );
      order = createOrder(
        product: p,
        quantity: widget.quantity,
        unitPrice: widget.unitPrice,
        buyer: me,
        method: 'kurir',
        courier: _courier,
        shippingFee: fee,
        paymentMethod: _payment!,
        addressText: address.oneLine,
      );
    } else {
      if (_placeCtrl.text.trim().isEmpty || _timeCtrl.text.trim().isEmpty) {
        showSnack(context, 'Isi titik temu dan waktu bertemu');
        return;
      }
      order = createOrder(
        product: p,
        quantity: widget.quantity,
        unitPrice: widget.unitPrice,
        buyer: me,
        method: 'cod',
        meetupPlace: _placeCtrl.text.trim(),
        meetupTime: _timeCtrl.text.trim(),
      );
    }

    if (widget.offer != null) markOfferCheckedOut(widget.offer!);

    // Ganti halaman checkout dengan halaman detail pesanan.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
    );
  }

  /// Kotak berjudul untuk mengelompokkan isi halaman.
  Widget _section(String title, Widget child) {
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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _costRow(String label, int value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
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

  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final p = widget.product;
    final seller = userById(p.sellerId)!;
    final sellerCity = cityOf(seller.id);
    final canCod = _sameCity(me.defaultAddress?.city, sellerCity);
    final address = _selectedAddress(me);

    final subtotal = widget.unitPrice * widget.quantity;
    final shipping = _method == 'kurir'
        ? shippingCost(
            _courier,
            _sameCity(address?.city, sellerCity),
            widget.quantity,
          )
        : 0;
    final total = subtotal + shipping;
    final canSubmit = _method == 'kurir' || canCod;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Ringkasan barang ----
          _section(
            'Barang',
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ProductImage(
                      path: p.imagePath,
                      category: p.category,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${formatRupiah(widget.unitPrice)} x ${widget.quantity}',
                      ),
                      if (widget.offer != null)
                        const Text(
                          'Harga hasil tawaran',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      Text(
                        'Penjual: ${seller.name}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ---- Pilih jalur transaksi ----
          _section(
            'Metode transaksi',
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'kurir',
                    label: Text('Kirim via kurir'),
                    icon: Icon(Icons.local_shipping_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'cod',
                    label: Text('COD'),
                    icon: Icon(Icons.people_outline),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
            ),
          ),
          // ================= JALUR KURIR =================
          if (_method == 'kurir') ...[
            _section(
              'Alamat pengiriman',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (me.addresses.isEmpty)
                    const Text('Kamu belum punya alamat.'),
                  for (final a in me.addresses)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        a.id == _addressId
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: a.id == _addressId
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text('${a.label} - ${a.receiver}'),
                      subtitle: Text('${a.fullAddress}, ${a.city}'),
                      onTap: () => setState(() => _addressId = a.id),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: Text(me.addresses.isEmpty
                        ? 'Tambah alamat'
                        : 'Kelola alamat'),
                    onPressed: _openAddressPage,
                  ),
                ],
              ),
            ),
            _section(
              'Kurir',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in couriers.keys)
                    ChoiceChip(
                      label: Text(
                        '$name • ${formatRupiah(shippingCost(name, _sameCity(address?.city, sellerCity), widget.quantity))}',
                      ),
                      selected: _courier == name,
                      onSelected: (_) => setState(() => _courier = name),
                    ),
                ],
              ),
            ),
            _section(
              'Metode pembayaran',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transfer bank',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final b in bankProviders)
                        ChoiceChip(
                          label: Text(b),
                          selected: _payment == b,
                          onSelected: (_) => setState(() => _payment = b),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('E-wallet', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final w in ewalletProviders)
                        ChoiceChip(
                          label: Text(w),
                          selected: _payment == w,
                          onSelected: (_) => setState(() => _payment = w),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pembayaran bersifat simulasi (tidak ada uang sungguhan). '
                    'Dana ditahan sampai kamu konfirmasi barang diterima.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          // ================= JALUR COD =================
          if (_method == 'cod')
            _section(
              'Bertemu langsung (COD)',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!canCod)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'COD hanya bisa jika kota alamat utamamu sama dengan kota penjual '
                        '(${sellerCity ?? "belum diatur"}). '
                        'Atur alamat utama di Profil > Alamat saya.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  if (canCod) ...[
                    const Text(
                      'Tanpa ongkir. Bayar tunai saat bertemu. '
                      'Penjual perlu menyetujui jadwalmu.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _placeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titik temu',
                        hintText: 'Contoh: Depan Indomaret Jl. Kaliurang',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _timeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Waktu bertemu',
                        hintText: 'Contoh: Sabtu, 10.00 WIB',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // ---- Rincian biaya ----
          _section(
            'Rincian pembayaran',
            Column(
              children: [
                _costRow('Subtotal', subtotal),
                if (_method == 'kurir') _costRow('Ongkos kirim', shipping),
                const Divider(),
                _costRow('Total', total, bold: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: Text('Buat pesanan • ${formatRupiah(total)}'),
          ),
        ),
      ),
    );
  }
}
