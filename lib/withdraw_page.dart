import 'package:flutter/material.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amountCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _accountId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final accounts = currentUser!.payoutAccounts;
    if (accounts.isNotEmpty) _accountId = accounts.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  PayoutAccount? _selectedAccount() {
    for (final a in currentUser!.payoutAccounts) {
      if (a.id == _accountId) return a;
    }
    return null;
  }

  Future<void> _addAccount() async {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: currentUser!.name);
    String provider = bankProviders.first;
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tambah rekening / e-wallet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in [...bankProviders, ...ewalletProviders])
                      ChoiceChip(
                        label: Text(p),
                        selected: provider == p,
                        onSelected: (_) => setLocal(() => provider = p),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: bankProviders.contains(provider)
                        ? 'Nomor rekening'
                        : 'Nomor e-wallet',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama pemilik',
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final number = numberCtrl.text.trim();
                if (number.length < 6 || int.tryParse(number) == null) {
                  setLocal(() => error = 'Nomor tidak valid (minimal 6 angka)');
                  return;
                }
                if (nameCtrl.text.trim().isEmpty) {
                  setLocal(() => error = 'Nama pemilik wajib diisi');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final account = PayoutAccount(
      id: newId(),
      provider: provider,
      number: numberCtrl.text.trim(),
      holderName: nameCtrl.text.trim(),
    );
    addPayoutAccount(account);
    if (!mounted) return;
    setState(() => _accountId = account.id);
  }

  Future<void> _deleteAccount(PayoutAccount a) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus rekening',
      message: 'Hapus ${a.title}?',
      confirmText: 'Hapus',
    );
    if (!ok) return;
    deletePayoutAccount(a.id);
    if (!mounted) return;
    setState(() {
      if (_accountId == a.id) {
        final rest = currentUser!.payoutAccounts;
        _accountId = rest.isEmpty ? null : rest.first.id;
      }
    });
  }

  void _withdraw() {
    final me = currentUser!;
    final account = _selectedAccount();
    final amount = int.tryParse(_amountCtrl.text.trim());
    final available = availableBalanceOf(me.id);

    String? error;
    if (account == null) {
      error = 'Pilih atau tambah rekening tujuan dulu';
    } else if (amount == null) {
      error = 'Masukkan jumlah penarikan';
    } else if (amount < minWithdraw) {
      error = 'Minimal penarikan ${formatRupiah(minWithdraw)}';
    } else if (amount > available) {
      error = 'Saldo tidak cukup (tersedia ${formatRupiah(available)})';
    } else if (_passCtrl.text != me.password) {
      error = 'Password salah';
    }

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    withdrawBalance(me.id, amount!, account!);
    Navigator.pop(context);
    showSnack(context, 'Penarikan ${formatRupiah(amount)} berhasil (simulasi)');
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final available = availableBalanceOf(me.id);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tarik saldo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Saldo tersedia: ${formatRupiah(available)}'),
          const SizedBox(height: 16),
          const Text(
            'Rekening tujuan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (me.payoutAccounts.isEmpty)
            const Text('Belum ada rekening tujuan.'),
          for (final a in me.payoutAccounts)
            Card(
              child: ListTile(
                leading: Icon(
                  a.id == _accountId
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: a.id == _accountId ? scheme.primary : null,
                ),
                title: Text(a.title),
                subtitle: Text(a.holderName),
                onTap: () => setState(() => _accountId = a.id),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteAccount(a),
                ),
              ),
            ),
          TextButton.icon(
            onPressed: _addAccount,
            icon: const Icon(Icons.add),
            label: const Text('Tambah rekening / e-wallet'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah penarikan',
              prefixText: 'Rp ',
              helperText: 'Minimal ${formatRupiah(minWithdraw)}',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Tarik semua'),
                onPressed: () => setState(() {
                  _amountCtrl.text = '$available';
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Konfirmasi password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _withdraw,
            child: const Text('Tarik saldo'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Penarikan bersifat simulasi (tidak ada uang sungguhan).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
