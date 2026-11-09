// ============================================================
// wallet_page.dart  -  Saldo penjual & riwayat
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - nilai yang dihitung dari data lain (saldo = masuk - tarik)
//  - menampilkan riwayat dengan warna hijau (masuk) / merah (tarik)
//  - konsep "saldo tertahan" (rekber / escrow) sederhana
// ============================================================

import 'package:flutter/material.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'withdraw_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final available = availableBalanceOf(me.id);
    final pending = pendingBalanceOf(me.id);
    final history = walletHistoryOf(me.id);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Saldo & penarikan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo tersedia',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(available),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.south_west),
                      label: const Text('Tarik saldo'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WithdrawPage(),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hourglass_bottom),
              title: const Text('Saldo tertahan'),
              subtitle: const Text(
                'Dana pesanan kurir yang sudah dibayar pembeli, '
                'cair setelah pembeli konfirmasi barang diterima.',
              ),
              trailing: Text(
                formatRupiah(pending),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Riwayat mutasi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada mutasi saldo.')),
            ),
          for (final e in history)
            Card(
              child: ListTile(
                leading: Icon(
                  e.isIncome ? Icons.south_west : Icons.north_east,
                  color: e.isIncome ? Colors.green : Colors.red,
                ),
                title: Text(e.note),
                subtitle: Text(formatDateTime(e.createdAt)),
                trailing: Text(
                  '${e.isIncome ? "+" : "-"} ${formatRupiah(e.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: e.isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
