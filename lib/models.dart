// ============================================================
// models.dart  -  "Cetakan" data aplikasi
// ------------------------------------------------------------
// YANG DIPELAJARI DI SINI:
//  - class dan constructor dengan named parameter
//  - field final (tidak bisa diganti) vs field biasa (bisa diubah)
//  - getter (get) untuk nilai yang dihitung dari field lain
//
// Satu class = satu jenis data. Contoh: Product = satu barang.
// ============================================================

/// Alamat pengiriman milik user.
class Address {
  Address({
    required this.id,
    required this.label,
    required this.receiver,
    required this.phone,
    required this.city,
    required this.fullAddress,
    this.isDefault = false,
  });

  final String id;
  final String label; // contoh: Rumah, Kantor
  final String receiver;
  final String phone;
  final String city;
  final String fullAddress;
  bool isDefault; // alamat utama atau bukan

  /// Teks alamat satu paket, dipakai di pesanan.
  String get oneLine => '$receiver ($phone)\n$fullAddress, $city';
}

/// Rekening bank / e-wallet tujuan penarikan saldo.
class PayoutAccount {
  PayoutAccount({
    required this.id,
    required this.provider,
    required this.number,
    required this.holderName,
  });

  final String id;
  final String provider; // BCA, GoPay, dst.
  final String number;
  final String holderName;

  String get title => '$provider - $number';
}

/// Satu akun pengguna. Satu akun bisa jadi penjual sekaligus pembeli.
class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.joinedAt,
    this.bio = '',
    List<String>? wishlist,
    List<String>? following,
    List<Address>? addresses,
    List<PayoutAccount>? payoutAccounts,
  })  : wishlist = wishlist ?? [],
        following = following ?? [],
        addresses = addresses ?? [],
        payoutAccounts = payoutAccounts ?? [];

  final String id;
  String name;
  final String email;
  final String password;
  String bio;
  final DateTime joinedAt;

  final List<String> wishlist; // daftar id produk favorit
  final List<String> following; // daftar id user yang diikuti
  final List<Address> addresses;
  final List<PayoutAccount> payoutAccounts;

  /// Alamat utama (atau alamat pertama jika belum ada yang utama).
  Address? get defaultAddress {
    for (final a in addresses) {
      if (a.isDefault) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }
}

/// Satu barang yang dijual.
class Product {
  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.size,
    required this.condition,
    required this.createdAt,
    this.conditionNote = '',
    this.imagePath,
    this.stock = 1,
  });

  final String id;
  final String sellerId;
  String title;
  String description;
  int price;
  String category;
  String size;
  String condition; // Like New / Good / Ada Minus
  String conditionNote; // catatan cacat (wajib jika "Ada Minus")
  String? imagePath; // lokasi file foto di HP (boleh kosong)
  int stock;
  final DateTime createdAt;

  /// Stok 0 berarti habis / terjual.
  bool get isSold => stock <= 0;
}

/// Daftar status tawaran.
class OfferStatus {
  static const waiting = 'menunggu'; // menunggu jawaban penjual
  static const countered = 'counter'; // penjual membalas dengan harga lain
  static const accepted = 'disetujui'; // sudah disetujui, tinggal checkout
  static const rejected = 'ditolak';
  static const checkedOut = 'dicheckout'; // sudah jadi pesanan
}

/// Tawaran harga dari pembeli.
class Offer {
  Offer({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.sellerId,
    required this.price,
    required this.quantity,
    required this.createdAt,
    this.status = OfferStatus.waiting,
  });

  final String id;
  final String productId;
  final String productTitle;
  final String buyerId;
  final String sellerId;
  int price; // harga per barang yang sedang dinegosiasikan
  final int quantity;
  final DateTime createdAt;
  String status;
}

/// Daftar status pesanan.
class OrderStatus {
  // Jalur kurir
  static const awaitingPayment = 'menunggu_bayar';
  static const paid = 'dibayar';
  static const packed = 'dikemas';
  static const shipped = 'dikirim';
  // Jalur COD (ketemuan langsung)
  static const awaitingMeetup = 'menunggu_jadwal';
  static const meetupApproved = 'jadwal_disetujui';
  // Dipakai keduanya
  static const done = 'selesai';
  static const cancelled = 'dibatalkan';
}

/// Satu pesanan (hasil checkout).
class Order {
  Order({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.unitPrice,
    required this.quantity,
    required this.buyerId,
    required this.sellerId,
    required this.method,
    required this.status,
    required this.createdAt,
    this.courier = '',
    this.shippingCost = 0,
    this.paymentMethod = '',
    this.paymentCode = '',
    this.addressText = '',
    this.meetupPlace = '',
    this.meetupTime = '',
    this.resi = '',
    this.cancelReason = '',
    this.cancelledBy,
  });

  final String id;
  final String productId;
  final String productTitle; // disalin saat checkout
  final int unitPrice; // harga per barang saat checkout
  final int quantity;
  final String buyerId;
  final String sellerId;
  final String method; // 'kurir' atau 'cod'
  String status;
  final DateTime createdAt;

  final String courier;
  final int shippingCost;
  final String paymentMethod;
  final String paymentCode;
  final String addressText;
  final String meetupPlace;
  final String meetupTime;
  String resi;
  String cancelReason;
  String? cancelledBy; // id user yang membatalkan

  bool get isCourier => method == 'kurir';
  int get subtotal => unitPrice * quantity;
  int get total => subtotal + shippingCost;

  /// Pesanan masih berjalan (belum selesai / batal).
  bool get isActive =>
      status != OrderStatus.done && status != OrderStatus.cancelled;

  /// Dana pembeli sudah masuk tapi belum cair ke penjual (saldo tertahan).
  bool get holdsEscrow =>
      isCourier &&
      (status == OrderStatus.paid ||
          status == OrderStatus.packed ||
          status == OrderStatus.shipped);

  /// Masih boleh dibatalkan?
  bool get canCancel {
    if (isCourier) {
      return status == OrderStatus.awaitingPayment ||
          status == OrderStatus.paid ||
          status == OrderStatus.packed;
    }
    return status == OrderStatus.awaitingMeetup ||
        status == OrderStatus.meetupApproved;
  }
}

/// Satu baris riwayat saldo (uang masuk atau penarikan).
class WalletEntry {
  WalletEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type; // 'masuk' atau 'tarik'
  final int amount;
  final String note;
  final DateTime createdAt;

  bool get isIncome => type == 'masuk';
}

/// Satu pesan chat.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.createdAt,
    this.productId,
    this.isRead = false,
  });

  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime createdAt;
  final String? productId; // barang yang dibahas (boleh kosong)
  bool isRead;
}
