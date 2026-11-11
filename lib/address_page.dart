import 'package:flutter/material.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  /// Dialog form. Jika [existing] diisi, mode edit.
  Future<void> _showForm([Address? existing]) async {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final receiverCtrl = TextEditingController(
      text: existing?.receiver ?? currentUser!.name,
    );
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final fullCtrl = TextEditingController(text: existing?.fullAddress ?? '');
    bool isDefault = existing?.isDefault ?? currentUser!.addresses.isEmpty;
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Tambah alamat' : 'Edit alamat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label (Rumah, Kantor...)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: receiverCtrl,
                  decoration: const InputDecoration(labelText: 'Nama penerima'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No. HP'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'Kota'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fullCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat lengkap',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Jadikan alamat utama'),
                  value: isDefault,
                  onChanged: (v) => setLocal(() => isDefault = v),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
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
                if (labelCtrl.text.trim().isEmpty ||
                    receiverCtrl.text.trim().isEmpty ||
                    phoneCtrl.text.trim().isEmpty ||
                    cityCtrl.text.trim().isEmpty ||
                    fullCtrl.text.trim().isEmpty) {
                  setLocal(() => error = 'Semua kolom wajib diisi');
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
    saveAddress(Address(
      id: existing?.id ?? newId(),
      label: labelCtrl.text.trim(),
      receiver: receiverCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      fullAddress: fullCtrl.text.trim(),
      isDefault: isDefault,
    ));
    if (mounted) setState(() {});
  }

  Future<void> _delete(Address a) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus alamat',
      message: 'Hapus alamat "${a.label}"?',
      confirmText: 'Hapus',
    );
    if (!ok) return;
    deleteAddress(a.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Alamat saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Tambah alamat'),
      ),
      body: me.addresses.isEmpty
          ? const EmptyState(
              icon: Icons.location_off_outlined,
              message: 'Belum ada alamat.\nTambahkan alamat untuk checkout.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                for (final a in me.addresses)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                a.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (a.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Utama',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${a.receiver} (${a.phone})'),
                          Text('${a.fullAddress}, ${a.city}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (!a.isDefault)
                                TextButton(
                                  onPressed: () {
                                    setDefaultAddress(a.id);
                                    setState(() {});
                                  },
                                  child: const Text('Jadikan utama'),
                                ),
                              TextButton(
                                onPressed: () => _showForm(a),
                                child: const Text('Edit'),
                              ),
                              TextButton(
                                onPressed: () => _delete(a),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
