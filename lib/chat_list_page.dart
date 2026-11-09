// ============================================================
// chat_list_page.dart  -  Daftar percakapan
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - ListTile dengan avatar, subtitle, dan badge belum dibaca
//  - membuka halaman chat dengan mengirim id lawan bicara
// ============================================================

import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'data_store.dart';
import 'helpers.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final partnerIds = chatPartnersOf(me.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan')),
      body: partnerIds.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              message:
                  'Belum ada percakapan.\nMulai chat dari halaman barang atau lapak penjual.',
            )
          : ListView.separated(
              itemCount: partnerIds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final other = userById(partnerIds[i]);
                if (other == null) return const SizedBox.shrink();

                final msgs = messagesBetween(me.id, other.id);
                final last = msgs.last;
                final unread = unreadFrom(me.id, other.id);

                return ListTile(
                  leading: CircleAvatar(child: Text(initialOf(other.name))),
                  title: Text(
                    other.name,
                    style: TextStyle(
                      fontWeight:
                          unread > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${last.fromId == me.id ? "Kamu: " : ""}${last.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatTime(last.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (unread > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Badge(label: Text('$unread')),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(otherUserId: other.id),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
    );
  }
}
