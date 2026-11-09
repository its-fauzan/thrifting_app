// ============================================================
// helpers.dart  -  Fungsi & widget kecil yang dipakai banyak halaman
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - fungsi biasa (format uang, tanggal)
//  - dialog (AlertDialog) dan SnackBar
//  - membuat widget sendiri (ProductImage, EmptyState)
// ============================================================

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';

import 'models.dart';

// ---------------- FORMAT ----------------

/// 150000 -> "Rp 150.000"
String formatRupiah(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buffer.write(s[i]);
    final sisa = s.length - i;
    if (sisa > 1 && sisa % 3 == 1) buffer.write('.');
  }
  return 'Rp ${buffer.toString()}';
}

String _two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String formatDateTime(DateTime d) => '${formatDate(d)} ${formatTime(d)}';

String initialOf(String name) =>
    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

// ---------------- DIALOG & SNACKBAR ----------------

/// Pesan singkat di bagian bawah layar.
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Dialog Ya/Batal. Mengembalikan true jika user memilih Ya.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Ya',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Dialog dengan satu kolom isian. Mengembalikan teks, atau null jika dibatalkan.
Future<String?> askTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  bool numberOnly = false,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: numberOnly ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// ---------------- LABEL STATUS ----------------

String orderStatusLabel(String status) {
  switch (status) {
    case OrderStatus.awaitingPayment:
      return 'Menunggu pembayaran';
    case OrderStatus.paid:
      return 'Sudah dibayar';
    case OrderStatus.packed:
      return 'Dikemas';
    case OrderStatus.shipped:
      return 'Dikirim';
    case OrderStatus.awaitingMeetup:
      return 'Menunggu persetujuan jadwal';
    case OrderStatus.meetupApproved:
      return 'Jadwal disetujui';
    case OrderStatus.done:
      return 'Selesai';
    case OrderStatus.cancelled:
      return 'Dibatalkan';
    default:
      return status;
  }
}

Color orderStatusColor(String status) {
  if (status == OrderStatus.done) return Colors.green;
  if (status == OrderStatus.cancelled) return Colors.red;
  return Colors.orange;
}

String offerStatusLabel(String status) {
  switch (status) {
    case OfferStatus.waiting:
      return 'Menunggu penjual';
    case OfferStatus.countered:
      return 'Dibalas penjual';
    case OfferStatus.accepted:
      return 'Disetujui';
    case OfferStatus.rejected:
      return 'Ditolak';
    case OfferStatus.checkedOut:
      return 'Sudah di-checkout';
    default:
      return status;
  }
}

Color offerStatusColor(String status) {
  if (status == OfferStatus.accepted) return Colors.green;
  if (status == OfferStatus.rejected) return Colors.red;
  return Colors.orange;
}

// ---------------- WIDGET KECIL ----------------

/// Label status berwarna (misalnya "Dikirim").
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Atasan':
      return Icons.checkroom;
    case 'Bawahan':
      return Icons.dry_cleaning;
    case 'Outerwear':
      return Icons.ac_unit;
    case 'Dress':
      return Icons.woman;
    case 'Sepatu':
      return Icons.directions_walk;
    case 'Tas':
      return Icons.shopping_bag;
    case 'Aksesoris':
      return Icons.watch;
    default:
      return Icons.local_offer;
  }
}

/// Foto barang. Jika belum ada foto, tampil ikon sesuai kategori.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.path, required this.category});

  final String? path;
  final String category;

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p != null) {
      if (kIsWeb) {
        // Di web (Chrome), foto berupa alamat blob, jadi dibaca lewat jaringan.
        return Image.network(
          p,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
      if (File(p).existsSync()) {
        // Di Android/iOS, foto berupa file di HP.
        return Image.file(
          File(p),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        categoryIcon(category),
        size: 40,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}

/// Tampilan "kosong" (ikon + pesan) di tengah layar.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
