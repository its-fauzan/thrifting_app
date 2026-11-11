import 'package:flutter/material.dart';

import 'chat_list_page.dart';
import 'data_store.dart';
import 'helpers.dart';
import 'product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _category;
  String? _size;
  String? _condition;
  int? _maxPrice;
  String _sort = 'newest';
  bool _followingOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Apakah ada filter dari panel filter yang aktif? (untuk titik penanda)
  bool get _hasSheetFilters =>
      _size != null ||
      _condition != null ||
      _maxPrice != null ||
      _sort != 'newest';

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(
        size: _size,
        condition: _condition,
        maxPrice: _maxPrice,
        sort: _sort,
        onApply: (size, condition, maxPrice, sort) {
          setState(() {
            _size = size;
            _condition = condition;
            _maxPrice = maxPrice;
            _sort = sort;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser!;
    final unread = unreadTotal(me.id);
    final items = filterProducts(
      query: _query,
      category: _category,
      size: _size,
      condition: _condition,
      maxPrice: _maxPrice,
      sort: _sort,
      followingOnly: _followingOnly,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Pesan',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListPage()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Kolom pencarian + tombol filter ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Cari jaket, flannel, sneakers...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _openFilterSheet,
                  icon: Badge(
                    smallSize: 8,
                    isLabelVisible: _hasSheetFilters,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),
          // ---- Deretan chip kategori ----
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _chipPadding(
                  FilterChip(
                    avatar: const Icon(Icons.people_outline, size: 18),
                    label: const Text('Lapak diikuti'),
                    selected: _followingOnly,
                    onSelected: (v) => setState(() => _followingOnly = v),
                  ),
                ),
                _chipPadding(
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in categories)
                  _chipPadding(
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (v) =>
                          setState(() => _category = v ? c : null),
                    ),
                  ),
              ],
            ),
          ),
          // ---- Daftar barang ----
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    message: _followingOnly
                        ? 'Belum ada barang dari lapak yang kamu ikuti.'
                        : 'Tidak ada barang yang cocok dengan pencarianmu.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: productGridDelegate,
                    itemCount: items.length,
                    itemBuilder: (context, i) => ProductCard(
                      product: items[i],
                      onChanged: () => setState(() {}),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipPadding(Widget chip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: chip,
    );
  }
}

// ------------------------------------------------------------
// Panel filter (muncul dari bawah)
// ------------------------------------------------------------

const List<int?> _priceOptions = [null, 50000, 100000, 200000, 500000];

const Map<String, String> _sortOptions = {
  'newest': 'Terbaru',
  'low': 'Harga terendah',
  'high': 'Harga tertinggi',
};

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.size,
    required this.condition,
    required this.maxPrice,
    required this.sort,
    required this.onApply,
  });

  final String? size;
  final String? condition;
  final int? maxPrice;
  final String sort;
  final void Function(
    String? size,
    String? condition,
    int? maxPrice,
    String sort,
  ) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  // Salinan pilihan sementara. Baru dipakai saat tombol "Terapkan" ditekan.
  late String? _size = widget.size;
  late String? _condition = widget.condition;
  late int? _maxPrice = widget.maxPrice;
  late String _sort = widget.sort;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter & urutkan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _size,
            decoration: const InputDecoration(labelText: 'Ukuran'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua'),
              ),
              for (final s in sizes)
                DropdownMenuItem<String?>(value: s, child: Text(s)),
            ],
            onChanged: (v) => setState(() => _size = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _condition,
            decoration: const InputDecoration(labelText: 'Kondisi'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua'),
              ),
              for (final c in conditions)
                DropdownMenuItem<String?>(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _condition = v),
          ),
          const SizedBox(height: 16),
          const Text('Harga maksimal'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final price in _priceOptions)
                ChoiceChip(
                  label: Text(
                    price == null ? 'Semua' : '≤ ${formatRupiah(price)}',
                  ),
                  selected: _maxPrice == price,
                  onSelected: (_) => setState(() => _maxPrice = price),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Urutkan'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in _sortOptions.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _sort == entry.key,
                  onSelected: (_) => setState(() => _sort = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null, null, 'newest');
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_size, _condition, _maxPrice, _sort);
                    Navigator.pop(context);
                  },
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
