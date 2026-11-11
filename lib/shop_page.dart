import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'data_store.dart';
import 'helpers.dart';
import 'product_card.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.userId});

  final String userId;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = userById(widget.userId);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off,
          message: 'Lapak tidak ditemukan.',
        ),
      );
    }

    final me = currentUser!;
    final mine = user.id == me.id;
    final items = productsBySeller(user.id);
    final following = isFollowing(user.id);

    return Scaffold(
      appBar: AppBar(title: Text('Lapak ${user.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  initialOf(user.name),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      cityOf(user.id) ?? 'Lokasi belum diatur',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Bergabung ${formatDate(user.joinedAt)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(user.bio),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  _stat('${items.length}', 'Barang'),
                  _stat('${followersOf(user.id)}', 'Pengikut'),
                  _stat('${completedSalesCount(user.id)}', 'Pesanan\nselesai'),
                  _stat('${sellerCancelPercent(user.id)}%',
                      'Batal oleh\npenjual'),
                ],
              ),
            ),
          ),
          if (!mine) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => setState(() => toggleFollow(user.id)),
                    child: Text(following ? 'Mengikuti' : 'Ikuti'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(otherUserId: user.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Etalase',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada barang.')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: productGridDelegate,
              itemCount: items.length,
              itemBuilder: (context, i) => ProductCard(
                product: items[i],
                onChanged: () => setState(() {}),
              ),
            ),
        ],
      ),
    );
  }
}
