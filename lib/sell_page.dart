import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'data_store.dart';
import 'helpers.dart';
import 'models.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key, this.product});

  /// Jika diisi, halaman ini menjadi mode EDIT. Jika kosong, mode TAMBAH.
  final Product? product;

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _noteCtrl;
  late String _category;
  late String _size;
  late String _condition;
  String? _imagePath;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p == null ? '' : '${p.price}');
    _stockCtrl = TextEditingController(text: p == null ? '1' : '${p.stock}');
    _noteCtrl = TextEditingController(text: p?.conditionNote ?? '');
    _category = p?.category ?? categories.first;
    _size = p?.size ?? sizes.first;
    _condition = p?.condition ?? conditions.first;
    _imagePath = p?.imagePath;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dengan kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null) return;
    if (!mounted) return;
    setState(() => _imagePath = file.path);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final me = currentUser!;
    final price = int.parse(_priceCtrl.text.trim());
    final stock = int.parse(_stockCtrl.text.trim());
    // Catatan cacat hanya disimpan jika kondisinya "Ada Minus".
    final note = _condition == 'Ada Minus' ? _noteCtrl.text.trim() : '';

    final existing = widget.product;
    if (existing == null) {
      addProduct(
        Product(
          id: newId(),
          sellerId: me.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: price,
          category: _category,
          size: _size,
          condition: _condition,
          conditionNote: note,
          imagePath: _imagePath,
          stock: stock,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      // Mode edit: ubah langsung field milik barang yang sama.
      existing.title = _titleCtrl.text.trim();
      existing.description = _descCtrl.text.trim();
      existing.price = price;
      existing.category = _category;
      existing.size = _size;
      existing.condition = _condition;
      existing.conditionNote = note;
      existing.imagePath = _imagePath;
      existing.stock = stock;
      notifyData();
    }

    Navigator.pop(context);
    showSnack(
      context,
      _isEdit ? 'Barang diperbarui' : 'Barang berhasil dijual',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit barang' : 'Jual barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Foto ----
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ProductImage(path: _imagePath, category: _category),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_imagePath == null ? 'Tambah foto' : 'Ganti foto'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Nama barang'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama barang wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        prefixText: 'Rp ',
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Harga tidak valid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 1) return 'Minimal 1';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _size,
                decoration: const InputDecoration(labelText: 'Ukuran'),
                items: [
                  for (final s in sizes)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) => setState(() => _size = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(labelText: 'Kondisi'),
                items: [
                  for (final c in conditions)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _condition = v!),
              ),
              // Kolom catatan cacat hanya muncul jika "Ada Minus".
              if (_condition == 'Ada Minus') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan minus / cacat',
                    hintText: 'Contoh: ada noda kecil di lengan kiri',
                  ),
                  validator: (v) {
                    if (_condition == 'Ada Minus' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Wajib diisi jika kondisi "Ada Minus"';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(_isEdit ? 'Simpan perubahan' : 'Jual sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
