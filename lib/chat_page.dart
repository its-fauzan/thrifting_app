import 'package:flutter/material.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.otherUserId, this.productId});

  final String otherUserId;

  /// Barang yang dibahas. Dilampirkan pada pesan pertama yang dikirim.
  final String? productId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _pendingProductId;

  @override
  void initState() {
    super.initState();
    _pendingProductId = widget.productId;
    // Tandai pesan sudah dibaca SETELAH layar pertama selesai digambar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markConversationRead(currentUser!.id, widget.otherUserId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    sendMessage(
      fromId: currentUser!.id,
      toId: widget.otherUserId,
      text: text,
      productId: _pendingProductId,
    );
    _textCtrl.clear();
    setState(() => _pendingProductId = null);
    _scrollToBottom();
  }

  Widget _bubble(ChatMessage m, bool mine) {
    final scheme = Theme.of(context).colorScheme;
    final product = m.productId == null ? null : productById(m.productId!);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ProductImage(
                          path: product.imagePath,
                          category: product.category,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            formatRupiah(product.price),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text(m.text),
            const SizedBox(height: 2),
            Text(
              formatTime(m.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final other = userById(widget.otherUserId);
    final msgs = messagesBetween(me.id, widget.otherUserId);
    final pendingProduct =
        _pendingProductId == null ? null : productById(_pendingProductId!);

    return Scaffold(
      appBar: AppBar(title: Text(other?.name ?? 'Chat')),
      body: Column(
        children: [
          Expanded(
            child: msgs.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    message: 'Belum ada pesan.\nSapa dulu yuk!',
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) =>
                        _bubble(msgs[i], msgs[i].fromId == me.id),
                  ),
          ),
          if (pendingProduct != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.attach_file),
              title: Text(
                'Melampirkan: ${pendingProduct.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _pendingProductId = null),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
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
