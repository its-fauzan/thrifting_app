import 'package:flutter/material.dart';

import 'address_page.dart';
import 'chat_list_page.dart';
import 'data_store.dart';
import 'helpers.dart';
import 'login_page.dart';
import 'shop_page.dart';
import 'wallet_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> _editProfile() async {
    final me = currentUser!;
    final nameCtrl = TextEditingController(text: me.name);
    final bioCtrl = TextEditingController(text: me.bio);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio lapak'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    if (nameCtrl.text.trim().isEmpty) {
      if (mounted) showSnack(context, 'Nama tidak boleh kosong');
      return;
    }
    me.name = nameCtrl.text.trim();
    me.bio = bioCtrl.text.trim();
    notifyData();
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Keluar',
      message: 'Yakin ingin keluar dari akun ini?',
      confirmText: 'Keluar',
    );
    if (!ok) return;
    logoutUser();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final unread = unreadTotal(me.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                child: Text(
                  initialOf(me.name),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(me.email, style: const TextStyle(color: Colors.grey)),
                    if (me.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(me.bio),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  _stat('${productsBySeller(me.id).length}', 'Barang'),
                  _stat('${followersOf(me.id)}', 'Pengikut'),
                  _stat('${me.following.length}', 'Mengikuti'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profil'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Lapak saya'),
            subtitle: const Text('Lihat etalase seperti yang dilihat pembeli'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _go(ShopPage(userId: me.id)),
          ),
          ListTile(
            leading: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            title: const Text('Pesan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _go(const ChatListPage()),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Alamat saya'),
            subtitle: Text('${me.addresses.length} alamat tersimpan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _go(const AddressPage()),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Saldo & penarikan'),
            subtitle: Text(
              'Saldo tersedia ${formatRupiah(availableBalanceOf(me.id))}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _go(const WalletPage()),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Keluar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
