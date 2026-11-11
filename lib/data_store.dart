import 'dart:math';

import 'package:flutter/foundation.dart';

import 'models.dart';

// ---------------- KONSTANTA ----------------

const String appName = 'ThriftIn';

const List<String> categories = [
  'Atasan',
  'Bawahan',
  'Outerwear',
  'Dress',
  'Sepatu',
  'Tas',
  'Aksesoris',
];

const List<String> sizes = [
  'XS',
  'S',
  'M',
  'L',
  'XL',
  'XXL',
  'All Size',
  '38-39',
  '40-41',
  '42-43',
];

const List<String> conditions = ['Like New', 'Good', 'Ada Minus'];

/// Nama kurir dan pengali tarifnya (simulasi).
const Map<String, double> couriers = {
  'JNE Reguler': 1.0,
  'J&T Express': 0.9,
  'SiCepat': 1.1,
};

const List<String> bankProviders = ['BCA', 'BNI', 'Mandiri', 'BRI'];
const List<String> ewalletProviders = ['GoPay', 'OVO', 'DANA'];
const int minWithdraw = 20000;

// ---------------- DATA GLOBAL ----------------

List<User> users = [];
List<Product> products = [];
List<Offer> offers = [];
List<Order> orders = [];
List<WalletEntry> walletEntries = [];
List<ChatMessage> messages = [];

/// User yang sedang login (null = belum login).
User? currentUser;

/// Setiap kali data berubah, angka ini naik. Widget yang "mendengarkan"
/// (misalnya badge di menu bawah) akan menggambar ulang dirinya.
final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

void notifyData() {
  dataVersion.value++;
}

int _idCounter = 0;

/// Membuat id unik sederhana.
String newId() {
  _idCounter++;
  return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
}

String _randomDigits(int count) {
  final random = Random();
  final buffer = StringBuffer();
  for (int i = 0; i < count; i++) {
    buffer.write(random.nextInt(10));
  }
  return buffer.toString();
}

// ---------------- USER & LOGIN ----------------

User? userById(String? id) {
  if (id == null) return null;
  for (final u in users) {
    if (u.id == id) return u;
  }
  return null;
}

/// Mengembalikan pesan error, atau null jika berhasil.
String? loginUser(String email, String password) {
  final e = email.trim().toLowerCase();
  for (final u in users) {
    if (u.email.toLowerCase() == e) {
      if (u.password != password) return 'Password salah';
      currentUser = u;
      return null;
    }
  }
  return 'Email belum terdaftar';
}

/// Mengembalikan pesan error, atau null jika berhasil (langsung login).
String? registerUser(String name, String email, String password) {
  final e = email.trim().toLowerCase();
  for (final u in users) {
    if (u.email.toLowerCase() == e) return 'Email sudah terdaftar';
  }
  final user = User(
    id: newId(),
    name: name.trim(),
    email: e,
    password: password,
    joinedAt: DateTime.now(),
  );
  users.add(user);
  currentUser = user;
  return null;
}

void logoutUser() {
  currentUser = null;
}

String? cityOf(String userId) => userById(userId)?.defaultAddress?.city;

// ---------------- FAVORIT & IKUTI ----------------

bool isWishlisted(String productId) =>
    currentUser?.wishlist.contains(productId) ?? false;

void toggleWishlist(String productId) {
  final me = currentUser;
  if (me == null) return;
  if (!me.wishlist.remove(productId)) me.wishlist.add(productId);
}

bool isFollowing(String userId) =>
    currentUser?.following.contains(userId) ?? false;

void toggleFollow(String userId) {
  final me = currentUser;
  if (me == null || me.id == userId) return;
  if (!me.following.remove(userId)) me.following.add(userId);
}

int followersOf(String userId) {
  int count = 0;
  for (final u in users) {
    if (u.following.contains(userId)) count++;
  }
  return count;
}

// ---------------- ALAMAT & REKENING ----------------

void saveAddress(Address address) {
  final me = currentUser;
  if (me == null) return;
  final index = me.addresses.indexWhere((a) => a.id == address.id);
  if (index == -1) {
    me.addresses.add(address);
  } else {
    me.addresses[index] = address;
  }
  if (address.isDefault) {
    for (final a in me.addresses) {
      a.isDefault = a.id == address.id;
    }
  }
  _ensureOneDefault(me);
}

void setDefaultAddress(String id) {
  final me = currentUser;
  if (me == null) return;
  for (final a in me.addresses) {
    a.isDefault = a.id == id;
  }
}

void deleteAddress(String id) {
  final me = currentUser;
  if (me == null) return;
  me.addresses.removeWhere((a) => a.id == id);
  _ensureOneDefault(me);
}

/// Pastikan selalu ada satu alamat utama (jika alamat tidak kosong).
void _ensureOneDefault(User u) {
  if (u.addresses.isEmpty) return;
  if (!u.addresses.any((a) => a.isDefault)) {
    u.addresses.first.isDefault = true;
  }
}

void addPayoutAccount(PayoutAccount account) {
  currentUser?.payoutAccounts.add(account);
}

void deletePayoutAccount(String id) {
  currentUser?.payoutAccounts.removeWhere((a) => a.id == id);
}

// ---------------- PRODUK ----------------

Product? productById(String id) {
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
}

List<Product> productsBySeller(String sellerId) {
  final list = products.where((p) => p.sellerId == sellerId).toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

/// Barang yang tersedia (stok > 0) sesuai pencarian & filter.
/// sort: 'newest' (terbaru), 'low' (harga terendah), 'high' (harga tertinggi)
List<Product> filterProducts({
  String query = '',
  String? category,
  String? size,
  String? condition,
  int? maxPrice,
  String sort = 'newest',
  bool followingOnly = false,
}) {
  final q = query.trim().toLowerCase();
  final following = currentUser?.following ?? <String>[];

  final list = products.where((p) {
    if (p.isSold) return false;
    if (followingOnly && !following.contains(p.sellerId)) return false;
    if (category != null && p.category != category) return false;
    if (size != null && p.size != size) return false;
    if (condition != null && p.condition != condition) return false;
    if (maxPrice != null && p.price > maxPrice) return false;
    if (q.isNotEmpty) {
      final text = '${p.title} ${p.description} ${p.category}'.toLowerCase();
      if (!text.contains(q)) return false;
    }
    return true;
  }).toList();

  if (sort == 'low') {
    list.sort((a, b) => a.price.compareTo(b.price));
  } else if (sort == 'high') {
    list.sort((a, b) => b.price.compareTo(a.price));
  } else {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  return list;
}

void addProduct(Product product) {
  products.insert(0, product);
  notifyData();
}

/// Hapus barang. Tawaran aktif untuk barang ini otomatis ditolak.
void deleteProduct(String id) {
  products.removeWhere((p) => p.id == id);
  for (final o in offers) {
    if (o.productId == id &&
        (o.status == OfferStatus.waiting ||
            o.status == OfferStatus.countered ||
            o.status == OfferStatus.accepted)) {
      o.status = OfferStatus.rejected;
    }
  }
  notifyData();
}

/// Tandai terjual (stok 0) atau jual kembali (stok jadi 1).
void setSold(Product p, bool sold) {
  if (sold) {
    p.stock = 0;
  } else if (p.stock <= 0) {
    p.stock = 1;
  }
  notifyData();
}

// ---------------- TAWARAN ----------------

List<Offer> offersAsBuyer(String userId) {
  final list = offers
      .where((o) => o.buyerId == userId && o.status != OfferStatus.checkedOut)
      .toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

List<Offer> offersAsSeller(String userId) {
  final list = offers
      .where((o) => o.sellerId == userId && o.status != OfferStatus.checkedOut)
      .toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

/// Tawaran yang masih berjalan dari pembeli untuk satu barang.
Offer? activeOfferOf(String buyerId, String productId) {
  for (final o in offers) {
    if (o.buyerId == buyerId &&
        o.productId == productId &&
        (o.status == OfferStatus.waiting ||
            o.status == OfferStatus.countered ||
            o.status == OfferStatus.accepted)) {
      return o;
    }
  }
  return null;
}

void createOffer({
  required Product product,
  required User buyer,
  required int price,
  required int quantity,
}) {
  offers.add(Offer(
    id: newId(),
    productId: product.id,
    productTitle: product.title,
    buyerId: buyer.id,
    sellerId: product.sellerId,
    price: price,
    quantity: quantity,
    createdAt: DateTime.now(),
  ));
  notifyData();
}

/// Ubah status tawaran. Isi newPrice jika penjual membalas (counter).
void respondOffer(Offer offer, String status, {int? newPrice}) {
  offer.status = status;
  if (newPrice != null) offer.price = newPrice;
  notifyData();
}

void markOfferCheckedOut(Offer offer) {
  offer.status = OfferStatus.checkedOut;
  notifyData();
}

// ---------------- PESANAN ----------------

Order? orderById(String id) {
  for (final o in orders) {
    if (o.id == id) return o;
  }
  return null;
}

List<Order> purchasesOf(String userId) {
  final list = orders.where((o) => o.buyerId == userId).toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

List<Order> salesOf(String userId) {
  final list = orders.where((o) => o.sellerId == userId).toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

bool hasActiveOrderFor(String productId) {
  return orders.any((o) => o.productId == productId && o.isActive);
}

/// Ongkir simulasi: sekota lebih murah, tiap barang tambahan +Rp 3.000.
int shippingCost(String courier, bool sameCity, int quantity) {
  final base = sameCity ? 9000 : 18000;
  final extra = (quantity - 1) * 3000;
  final multiplier = couriers[courier] ?? 1.0;
  return ((base + extra) * multiplier / 100).round() * 100;
}

/// Membuat pesanan baru dan langsung mengurangi stok barang.
Order createOrder({
  required Product product,
  required int quantity,
  required int unitPrice,
  required User buyer,
  required String method, // 'kurir' atau 'cod'
  String courier = '',
  int shippingFee = 0,
  String paymentMethod = '',
  String addressText = '',
  String meetupPlace = '',
  String meetupTime = '',
}) {
  String paymentCode = '';
  if (method == 'kurir') {
    paymentCode = bankProviders.contains(paymentMethod)
        ? '8808${_randomDigits(10)}' // nomor virtual account (simulasi)
        : '0812${_randomDigits(8)}'; // nomor e-wallet (simulasi)
  }

  final order = Order(
    id: newId(),
    productId: product.id,
    productTitle: product.title,
    unitPrice: unitPrice,
    quantity: quantity,
    buyerId: buyer.id,
    sellerId: product.sellerId,
    method: method,
    status: method == 'kurir'
        ? OrderStatus.awaitingPayment
        : OrderStatus.awaitingMeetup,
    createdAt: DateTime.now(),
    courier: courier,
    shippingCost: shippingFee,
    paymentMethod: paymentMethod,
    paymentCode: paymentCode,
    addressText: addressText,
    meetupPlace: meetupPlace,
    meetupTime: meetupTime,
  );
  orders.add(order);

  product.stock = max(0, product.stock - quantity);
  notifyData();
  return order;
}

/// Batalkan pesanan. Stok barang dikembalikan.
void cancelOrder(Order order, String byUserId, String reason) {
  order.status = OrderStatus.cancelled;
  order.cancelledBy = byUserId;
  order.cancelReason = reason;
  final p = productById(order.productId);
  if (p != null) p.stock += order.quantity;
  notifyData();
}

void payOrder(Order order) {
  order.status = OrderStatus.paid;
  notifyData();
}

void packOrder(Order order) {
  order.status = OrderStatus.packed;
  notifyData();
}

void shipOrder(Order order) {
  order.resi =
      '${order.courier.split(' ').first.toUpperCase()}${_randomDigits(10)}';
  order.status = OrderStatus.shipped;
  notifyData();
}

void approveMeetup(Order order) {
  order.status = OrderStatus.meetupApproved;
  notifyData();
}

/// Pesanan selesai. Untuk jalur kurir, uang masuk ke saldo penjual.
/// Untuk COD, uang diterima tunai sehingga tidak masuk saldo.
void completeOrder(Order order) {
  order.status = OrderStatus.done;
  if (order.isCourier) {
    walletEntries.add(WalletEntry(
      id: newId(),
      userId: order.sellerId,
      type: 'masuk',
      amount: order.subtotal,
      note: 'Pesanan: ${order.productTitle}',
      createdAt: DateTime.now(),
    ));
  }
  notifyData();
}

// ---------------- SALDO ----------------

/// Saldo yang boleh ditarik = total uang masuk - total penarikan.
int availableBalanceOf(String userId) {
  int total = 0;
  for (final e in walletEntries) {
    if (e.userId == userId) {
      total += e.isIncome ? e.amount : -e.amount;
    }
  }
  return total;
}

/// Saldo tertahan = pesanan kurir yang sudah dibayar tapi belum selesai.
int pendingBalanceOf(String userId) {
  int total = 0;
  for (final o in orders) {
    if (o.sellerId == userId && o.holdsEscrow) total += o.subtotal;
  }
  return total;
}

List<WalletEntry> walletHistoryOf(String userId) {
  final list = walletEntries.where((e) => e.userId == userId).toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

void withdrawBalance(String userId, int amount, PayoutAccount account) {
  walletEntries.add(WalletEntry(
    id: newId(),
    userId: userId,
    type: 'tarik',
    amount: amount,
    note: 'Tarik ke ${account.title}',
    createdAt: DateTime.now(),
  ));
  notifyData();
}

// ---------------- STATISTIK PENJUAL ----------------

int completedSalesCount(String sellerId) {
  return orders
      .where((o) => o.sellerId == sellerId && o.status == OrderStatus.done)
      .length;
}

/// Persentase pesanan yang dibatalkan oleh penjual sendiri.
int sellerCancelPercent(String sellerId) {
  final all = orders.where((o) => o.sellerId == sellerId).toList();
  if (all.isEmpty) return 0;
  final cancelled = all
      .where(
          (o) => o.status == OrderStatus.cancelled && o.cancelledBy == sellerId)
      .length;
  return (cancelled * 100 / all.length).round();
}

/// Jumlah tawaran/pesanan yang menunggu tindakan user (untuk badge).
int actionCount(String userId) {
  int count = 0;
  for (final o in offers) {
    if (o.sellerId == userId && o.status == OfferStatus.waiting) count++;
    if (o.buyerId == userId &&
        (o.status == OfferStatus.countered ||
            o.status == OfferStatus.accepted)) {
      count++;
    }
  }
  for (final o in orders) {
    final sellerTurn = o.sellerId == userId &&
        (o.status == OrderStatus.paid ||
            o.status == OrderStatus.packed ||
            o.status == OrderStatus.awaitingMeetup);
    final buyerTurn = o.buyerId == userId &&
        (o.status == OrderStatus.awaitingPayment ||
            o.status == OrderStatus.shipped ||
            o.status == OrderStatus.meetupApproved);
    if (sellerTurn || buyerTurn) count++;
  }
  return count;
}

// ---------------- CHAT ----------------

void sendMessage({
  required String fromId,
  required String toId,
  required String text,
  String? productId,
}) {
  messages.add(ChatMessage(
    id: newId(),
    fromId: fromId,
    toId: toId,
    text: text,
    createdAt: DateTime.now(),
    productId: productId,
  ));
  notifyData();
}

/// Semua pesan antara dua user, dari yang paling lama.
List<ChatMessage> messagesBetween(String a, String b) {
  final list = messages
      .where((m) =>
          (m.fromId == a && m.toId == b) || (m.fromId == b && m.toId == a))
      .toList();
  list.sort((x, y) => x.createdAt.compareTo(y.createdAt));
  return list;
}

/// Daftar id lawan bicara, yang chat-nya paling baru ada di atas.
List<String> chatPartnersOf(String userId) {
  final latest = <String, DateTime>{};
  for (final m in messages) {
    String? other;
    if (m.fromId == userId) other = m.toId;
    if (m.toId == userId) other = m.fromId;
    if (other == null) continue;
    final old = latest[other];
    if (old == null || m.createdAt.isAfter(old)) latest[other] = m.createdAt;
  }
  final ids = latest.keys.toList();
  ids.sort((a, b) => latest[b]!.compareTo(latest[a]!));
  return ids;
}

int unreadFrom(String me, String other) {
  return messages
      .where((m) => m.toId == me && m.fromId == other && !m.isRead)
      .length;
}

int unreadTotal(String me) {
  return messages.where((m) => m.toId == me && !m.isRead).length;
}

void markConversationRead(String me, String other) {
  bool changed = false;
  for (final m in messages) {
    if (m.toId == me && m.fromId == other && !m.isRead) {
      m.isRead = true;
      changed = true;
    }
  }
  if (changed) notifyData();
}

// ----------------- Akun demo dan Data Contoh ----------------

void loadSeedData() {
  final now = DateTime.now();

  final rina = User(
    id: 'u1',
    name: 'Rina Putri',
    email: 'rina@mail.com',
    password: '123456',
    bio: 'Pecinta barang vintage. Semua barang dicuci sebelum dikirim.',
    joinedAt: now.subtract(const Duration(days: 120)),
    addresses: [
      Address(
        id: 'a1',
        label: 'Rumah',
        receiver: 'Rina Putri',
        phone: '081234567801',
        city: 'Yogyakarta',
        fullAddress: 'Jl. Kaliurang Km 5 No. 12',
        isDefault: true,
      ),
    ],
    payoutAccounts: [
      PayoutAccount(
        id: 'pa1',
        provider: 'BCA',
        number: '1234567890',
        holderName: 'Rina Putri',
      ),
    ],
  );

  final dimas = User(
    id: 'u2',
    name: 'Dimas Pratama',
    email: 'dimas@mail.com',
    password: '123456',
    bio: 'Suka hoodie dan celana cargo.',
    joinedAt: now.subtract(const Duration(days: 90)),
    following: ['u1'],
    wishlist: ['p1'],
    addresses: [
      Address(
        id: 'a2',
        label: 'Kos',
        receiver: 'Dimas Pratama',
        phone: '081234567802',
        city: 'Yogyakarta',
        fullAddress: 'Jl. Magelang Km 4 No. 8',
        isDefault: true,
      ),
    ],
  );

  final salsa = User(
    id: 'u3',
    name: 'Salsa Amelia',
    email: 'salsa@mail.com',
    password: '123456',
    bio: 'Koleksi dress dan kaos band.',
    joinedAt: now.subtract(const Duration(days: 60)),
    following: ['u1'],
    addresses: [
      Address(
        id: 'a3',
        label: 'Rumah',
        receiver: 'Salsa Amelia',
        phone: '081234567803',
        city: 'Jakarta',
        fullAddress: 'Jl. Kemang Raya No. 20',
        isDefault: true,
      ),
    ],
  );

  users = [rina, dimas, salsa];

  products = [
    Product(
      id: 'p1',
      sellerId: 'u1',
      title: 'Jaket Denim Vintage',
      description: 'Jaket denim washed, bahan tebal, masih sangat bagus.',
      price: 185000,
      category: 'Outerwear',
      size: 'L',
      condition: 'Good',
      imagePath: 'assets/images/denim_vintage.webp',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    Product(
      id: 'p2',
      sellerId: 'u1',
      title: 'Kemeja Flannel Kotak Merah',
      description: 'Flannel lembut, jarang dipakai.',
      price: 75000,
      category: 'Atasan',
      size: 'M',
      condition: 'Like New',
      imagePath: 'assets/images/flanel_merah.jpg',
      stock: 2,
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    Product(
      id: 'p3',
      sellerId: 'u1',
      title: 'Sneakers Canvas Putih',
      description: 'Sneakers canvas klasik.',
      price: 250000,
      category: 'Sepatu',
      size: '42-43',
      condition: 'Ada Minus',
      imagePath: 'assets/images/sneakers_putih.jpg',
      conditionNote: 'Sol sedikit menguning, tali sudah diganti baru.',
      createdAt: now.subtract(const Duration(days: 5)),
    ),
    Product(
      id: 'p4',
      sellerId: 'u2',
      title: 'Hoodie Hitam Oversize',
      description: 'Hoodie tebal, nyaman dipakai.',
      price: 220000,
      category: 'Outerwear',
      size: 'XL',
      condition: 'Good',
      imagePath: 'assets/images/hoodie_hitam.jpeg',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    Product(
      id: 'p5',
      sellerId: 'u2',
      title: 'Celana Cargo Army',
      description: 'Celana cargo banyak saku, warna hijau army.',
      price: 120000,
      category: 'Bawahan',
      size: 'L',
      condition: 'Good',
      imagePath: 'assets/images/cargo_army.jpg',
      stock: 3,
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    Product(
      id: 'p6',
      sellerId: 'u2',
      title: 'Tas Selempang Kanvas',
      description: 'Tas kanvas muat laptop 13 inci.',
      price: 65000,
      category: 'Tas',
      size: 'All Size',
      condition: 'Like New',
      imagePath: 'assets/images/tas_selempang.jpg',
      createdAt: now.subtract(const Duration(days: 6)),
    ),
    Product(
      id: 'p7',
      sellerId: 'u3',
      title: 'Dress Floral Vintage',
      description: 'Dress motif bunga, bahan adem.',
      price: 95000,
      category: 'Dress',
      size: 'M',
      condition: 'Like New',
      imagePath: 'assets/images/dress_floral.jpg',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    Product(
      id: 'p8',
      sellerId: 'u3',
      title: 'Kaos Band Rock',
      description: 'Kaos band tahun 90-an, sablon masih jelas.',
      price: 130000,
      category: 'Atasan',
      size: 'L',
      condition: 'Ada Minus',
      imagePath: 'assets/images/kaos_rock.jpg',
      conditionNote: 'Warna sedikit pudar di bagian kerah.',
      createdAt: now.subtract(const Duration(days: 7)),
    ),
    Product(
      id: 'p9',
      sellerId: 'u3',
      title: 'Topi Bucket Corduroy',
      description: 'Topi bucket warna cokelat.',
      price: 45000,
      category: 'Aksesoris',
      size: 'All Size',
      condition: 'Good',
      imagePath: 'assets/images/topi_bucket.jpg',
      createdAt: now.subtract(const Duration(days: 8)),
    ),
    Product(
      id: 'p10',
      sellerId: 'u3',
      title: 'Rok Plisket Hitam',
      description: 'Rok plisket panjang selutut.',
      price: 70000,
      category: 'Bawahan',
      size: 'S',
      condition: 'Like New',
      imagePath: 'assets/images/rok_plisket.jpg',
      createdAt: now.subtract(const Duration(days: 9)),
    ),
  ];

  // Tawaran masuk untuk Rina dari Dimas (bisa dicoba terima/tolak/counter).
  offers = [
    Offer(
      id: 'of1',
      productId: 'p1',
      productTitle: 'Jaket Denim Vintage',
      buyerId: 'u2',
      sellerId: 'u1',
      price: 150000,
      quantity: 1,
      createdAt: now.subtract(const Duration(hours: 4)),
    ),
  ];

  orders = [
    // Pesanan sudah dibayar Dimas, menunggu Rina memproses.
    Order(
      id: 'o1',
      productId: 'p2',
      productTitle: 'Kemeja Flannel Kotak Merah',
      unitPrice: 75000,
      quantity: 1,
      buyerId: 'u2',
      sellerId: 'u1',
      method: 'kurir',
      status: OrderStatus.paid,
      createdAt: now.subtract(const Duration(hours: 5)),
      courier: 'JNE Reguler',
      shippingCost: 9000,
      paymentMethod: 'BCA',
      paymentCode: '88081234567890',
      addressText: dimas.addresses.first.oneLine,
    ),
    // Pesanan lama yang sudah selesai (sumber saldo awal Rina).
    Order(
      id: 'o2',
      productId: 'p_lama',
      productTitle: 'Sweater Rajut Krem',
      unitPrice: 150000,
      quantity: 1,
      buyerId: 'u3',
      sellerId: 'u1',
      method: 'kurir',
      status: OrderStatus.done,
      createdAt: now.subtract(const Duration(days: 10)),
      courier: 'J&T Express',
      shippingCost: 16200,
      paymentMethod: 'GoPay',
      paymentCode: '081212345678',
      addressText: salsa.addresses.first.oneLine,
      resi: 'J&T0012345678',
    ),
  ];

  walletEntries = [
    WalletEntry(
      id: 'w1',
      userId: 'u1',
      type: 'masuk',
      amount: 150000,
      note: 'Pesanan: Sweater Rajut Krem',
      createdAt: now.subtract(const Duration(days: 8)),
    ),
  ];

  messages = [
    ChatMessage(
      id: 'm1',
      fromId: 'u2',
      toId: 'u1',
      text: 'Halo kak, jaket denimnya masih ada? Boleh nego?',
      createdAt: now.subtract(const Duration(hours: 3)),
      productId: 'p1',
    ),
  ];

  currentUser = null;
}
