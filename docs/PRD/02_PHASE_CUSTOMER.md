# Phase 2 — Customer Mobile App
**Branch:** `feature/fase-2-customer`
**PIC:** Anggota 1
**Estimasi:** 5–7 hari kerja
**Dependency:** Fase 1 harus sudah di-merge ke `develop`

---

## Objective

Membangun seluruh pengalaman pelanggan — booking, tracking real-time, pembayaran, ulasan, klaim garansi.

---

## Deliverables

- [ ] 13 screen selesai dan bisa di-build
- [ ] Booking flow tanpa JWT (pelanggan baru)
- [ ] Tracking real-time polling 30 detik
- [ ] Approval / rejection diagnosis dengan kartu detail
- [ ] Upload bukti pembayaran via presigned URL
- [ ] Submit review dengan animasi reward
- [ ] Klaim garansi (dispute) dengan upload bukti
- [ ] Profile + sessions management

---

## Scope

**Kerjakan:** `lib/features/customer/` seluruhnya + concrete repository impl.
**Jangan sentuh:** `lib/features/store_admin/`, `lib/core/`, `lib/shared/` (buka PR jika perlu ubah).

---

## Folder Structure

```
lib/features/customer/
├── screens/
│   ├── splash/splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── change_password_screen.dart
│   ├── home/home_screen.dart
│   ├── stores/
│   │   ├── store_list_screen.dart
│   │   └── store_detail_screen.dart
│   ├── booking/
│   │   ├── booking_form_screen.dart
│   │   └── booking_success_screen.dart
│   ├── orders/
│   │   ├── order_list_screen.dart
│   │   ├── order_detail_screen.dart
│   │   └── tracking_screen.dart
│   ├── payment/payment_upload_screen.dart
│   ├── review/
│   │   ├── review_form_screen.dart
│   │   └── review_success_screen.dart
│   ├── warranty/warranty_claim_screen.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── sessions_screen.dart
├── providers/
│   ├── auth_provider.dart
│   ├── store_provider.dart
│   ├── order_provider.dart
│   ├── payment_provider.dart
│   └── review_provider.dart
├── repositories/
│   ├── customer_auth_repository_impl.dart
│   ├── store_repository_impl.dart
│   ├── order_repository_impl.dart
│   ├── payment_repository_impl.dart
│   ├── review_repository_impl.dart
│   └── dispute_repository_impl.dart
└── widgets/
    ├── order_status_timeline.dart
    ├── store_card.dart
    ├── diagnosis_approval_card.dart
    ├── sparepart_selector_sheet.dart
    └── coupon_reward_banner.dart
```

---

## Screen Specifications

### 1. Splash Screen

```dart
@override
void initState() {
  super.initState();
  _checkAuth();
}

Future<void> _checkAuth() async {
  await Future.delayed(const Duration(milliseconds: 600));
  final token = await ref.read(secureStorageProvider).getAccessToken();
  if (token == null) { context.go('/login'); return; }
  try {
    final user = await ref.read(authRepositoryProvider).getMe();
    context.go(user.isFirstLogin ? '/change-password' : '/home');
  } catch (_) {
    await ref.read(secureStorageProvider).clearAll();
    context.go('/login');
  }
}
```

Tampilan: logo tengah + CircularProgressIndicator.

---

### 2. Login Screen

**Endpoint:** `POST /v1/auth/login`

```
Fields:
  Nomor HP  — TextFormField, keyboard: phone, auto-format +62
  Password  — TextFormField, obscureText, toggle visibility

Validasi client:
  HP: tidak boleh kosong
  Password: tidak boleh kosong

Error messages:
  INVALID_CREDENTIALS  → "Nomor HP atau password salah."
  ACCOUNT_LOCKED       → "Akun terkunci hingga {lockedUntil}."
  ACCOUNT_SUSPENDED    → "Akun dinonaktifkan. Hubungi support."

Sukses:
  Simpan access_token + refresh_token ke SecureStorage
  Jika is_first_login=true → context.go('/change-password')
  Else                     → context.go('/home')
```

Tidak ada tombol "Daftar" — pelanggan mendapat akun otomatis saat booking.

---

### 3. Change Password Screen

**Endpoint:** `POST /v1/auth/change-password`

```
Banner jika isFirstLogin=true:
  "Ganti password sementaramu sebelum melanjutkan."
  (warna kuning, tidak bisa di-dismiss)

Fields:
  Password Lama
  Password Baru (min 8 karakter)
  Konfirmasi Password Baru

Validasi:
  Password Baru != Password Lama (cek di client sebelum submit)
  Konfirmasi harus sama dengan Password Baru

Tidak ada tombol Skip jika isFirstLogin=true.

Sukses → context.go('/home')
Error PASSWORD_SAME_AS_OLD → "Password baru tidak boleh sama dengan yang lama."
```

---

### 4. Home Screen

**Endpoints:** `GET /v1/me`, `GET /v1/me/summary`, `GET /v1/me/orders?limit=3`

```
Layout (scroll vertikal):
  Header:
    Greeting: "Halo, {nama}!" + avatar
    
  Summary Row (3 card):
    Pesanan Aktif  | Kupon Aktif | Dalam Garansi
    
  Quick Actions (3 button):
    [Servis Sekarang] → /stores
    [Pesanan Saya]    → /orders
    [Kupon Saya]      → /coupons
    
  Recent Orders (max 3 item):
    Tiap item: nomor order, nama toko, status badge, tanggal
    Tombol "Lihat Semua" → /orders
    
  Banner promo (static untuk MVP, gambar dari assets)
```

Pull-to-refresh memuat ulang semua section.

---

### 5. Store List Screen

**Endpoint:** `GET /v1/stores?brand=&deviceModel=&page=&limit=20`

```
Filter bar (horizontal scroll chips):
  Brand: Samsung | Apple | Xiaomi | Oppo | Realme | Vivo | All
  Model: text input + search

List item (StoreCard widget):
  Nama toko
  ⭐ {ratingAvg} ({jumlah review} ulasan)
  Alamat (1 baris, truncate)
  Badge: ✓ Verified (jika verifiedAt != null)

Tap → /stores/:id
```

---

### 6. Store Detail Screen

**Endpoints:** `GET /v1/stores/:id`, `GET /v1/store/spareparts?storeId=:id`

```
Header: foto toko / placeholder, nama, rating, badge
Info: alamat (tap → maps), telepon (tap → call), jam operasional

TabBar: [Sparepart] [Ulasan]

Tab Sparepart:
  Filter chips: Layar | Baterai | Port | Kamera | Lainnya
  List item per sparepart:
    Nama part
    Rp {price}
    Stok: {qty-qtyReserved} tersedia | "Habis" (merah) jika 0
    
Tab Ulasan:
  List: avatar, nama, ⭐⭐⭐, komentar, tanggal

FAB bawah: "Buat Order" → /booking/:storeId
```

---

### 7. Booking Form Screen

**Endpoint:** `POST /v1/orders` (PUBLIC — kirim TANPA Authorization header)

```dart
// Repository implementation — tidak pakai interceptor JWT
class OrderRepositoryImpl implements OrderRepository {
  final Dio _publicDio;   // ApiClient.createPublicDio()
  final Dio _authDio;     // ApiClient.createAuthenticatedDio()

  @override
  Future<CreateOrderResult> createOrder(CreateOrderRequest req) async {
    // Gunakan publicDio — tidak ada JWT
    final resp = await _publicDio.post('/orders', data: req.toJson());
    return CreateOrderResult.fromJson(resp.data['data']);
  }
}
```

```
Section Info Pelanggan:
  Nama Lengkap *        (pre-fill dari profil jika login)
  Nomor HP *            (pre-fill jika login, auto-format +62)

Section Info Perangkat:
  Jenis Device *        (segmented: Android / iOS)
  Brand *               (text)
  Model Device *        (text)

Section Kerusakan (bisa multiple item):
  Jenis Servis *        (dropdown: Layar/Baterai/Port/Kamera/Lainnya)
  Deskripsi *           (textarea, min 10 karakter)
  Pilih Sparepart       (optional, buka SparePartSelectorSheet)
    → tampilkan: nama, harga, stok tersedia
    → item disabled jika stok = 0

Section Pengiriman:
  Metode *              (segmented: Antar Sendiri / Pickup Kurir)
  Alamat Pickup *       (muncul hanya jika Pickup Kurir)

Section Lainnya:
  Kode Kupon            (optional, note: "Kupon hanya untuk akun yang sudah ada")

Preview Estimasi (sticky bottom bar):
  Estimasi: Rp {totalEstimasi}   [Buat Order →]

Submit:
  Validasi semua field
  Kirim tanpa Authorization header
  Loading state
  Sukses  → /booking-success/:orderNumber (+ isNewCustomer dari response)
  409     → "Stok sparepart habis, pilih sparepart lain."
  422     → "Toko tidak aktif."
```

---

### 8. Booking Success Screen

```
Ilustrasi sukses (animasi Lottie atau static)

Nomor Order: SG-{date}-{id}

Pesan: "Order berhasil dibuat!
        Admin toko akan segera mengkonfirmasi."

Banner jika isNewCustomer=true:
  "Cek WhatsApp kamu — admin toko akan mengirimkan
   informasi akun ServisGadget."

Tombol: [Lihat Detail Pesanan]  [Kembali ke Beranda]
```

---

### 9. Order List Screen

**Endpoint:** `GET /v1/me/orders?status=&page=&limit=20`

```
TabBar: [Aktif] [Selesai] [Dibatalkan]

Filter aktif = status IN:
  waiting_device, device_received, diagnosing, waiting_approval,
  waiting_sparepart, repairing, quality_check, waiting_payment, disputed

List item:
  Nomor order                [STATUS BADGE]
  Nama toko
  {brand} {model}
  {tanggal}         [⏰ jika slaDeadline < 6 jam → teks merah]

Tap → /orders/:id
Pull-to-refresh + infinite scroll pagination
```

---

### 10. Order Detail Screen

**Endpoint:** `GET /v1/orders/:id`

```
Header: nomor order | status badge | tanggal

Section Info Perangkat:
  Brand, model, jenis device
  Metode pengiriman + alamat (jika courier)

Section Toko:
  Nama, alamat, tombol telpon

Section Harga:
  Estimasi:      Rp {totalEstimasi}
  Diskon:        -Rp {discountAmount}  (hanya tampil jika > 0)
  Final:         Rp {finalPrice}       (hanya tampil jika sudah diagnosis)

Section Item Order:
  Per item: jenis servis, deskripsi, sparepart, harga estimasi → final

Section Tracking (kompak, 3 terbaru):
  Tombol "Lihat Semua" → /orders/:id/tracking

Section Pembayaran:
  Riwayat payment (jika ada)
  Status: pending / confirmed

SLA Deadline Bar (muncul jika slaDeadline ada):
  Merah jika < 6 jam: "⏰ Batas waktu: {countdown}"

DiagnosisApprovalCard (muncul hanya saat waiting_approval):
  ┌────────────────────────────────────┐
  │ 🔧 Hasil Diagnosa                  │
  │ Catatan: {diagnosisNote}           │
  │                                    │
  │ Rincian:                           │
  │  • {item} — Rp {finalItemPrice}    │
  │  • Service Fee — Rp {serviceFee}   │
  │ ──────────────────────────────────│
  │ Total: Rp {finalPrice}             │
  │                                    │
  │ Batas: {slaDeadline}               │
  │ [✅ Setuju]        [❌ Tolak]       │
  └────────────────────────────────────┘

Action Buttons:
  waiting_payment  → [Upload Bukti Bayar]  → /orders/:id/payment
  completed + !reviewed → [Beri Ulasan]    → /orders/:id/review
  completed + in warranty → [Klaim Garansi] → /orders/:id/warranty-claim

Tombol Setuju → POST /v1/orders/:id/approve → invalidate provider
Tombol Tolak  → showDialog konfirmasi → POST /v1/orders/:id/reject
```

---

### 11. Tracking Screen

**Endpoint:** `GET /v1/me/orders/:id/progress`

```dart
// Provider dengan polling 30 detik
@riverpod
Stream<OrderProgressResponse> orderTracking(
  OrderTrackingRef ref,
  String orderId,
) async* {
  final repo = ref.read(orderRepositoryProvider);
  yield await repo.getOrderProgress(orderId);
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await repo.getOrderProgress(orderId);
  }
}
```

```
Timeline Widget (OrderStatusTimeline):
  Urutan: terbaru di atas

  Per entry:
    ● (filled dot = sudah selesai, outline = current)
    Status label (terjemahan Bahasa Indonesia)
    Note (jika ada)
    Timestamp: dd MMM yyyy, HH:mm

  Garis konektor vertikal antara dot

Footer: "Diperbarui: {HH:mm}" — update tiap poll
```

---

### 12. Payment Upload Screen

**Endpoints:** `POST /v1/uploads/presign`, `POST /v1/orders/:id/payments`

```
Header info:
  Order: {orderNumber}
  Final Price: Rp {finalPrice}
  Sudah Bayar: Rp {totalConfirmed}    (dari riwayat payment confirmed)
  Sisa:        Rp {sisa}             (pre-fill di field nominal)

Form:
  Metode Pembayaran *
    [Transfer Bank] [QRIS] [Tunai] [E-Wallet]

  Jenis Pembayaran *
    [Uang Muka]  [Pelunasan Final]

  Nominal (Rp) *
    (pre-fill dengan sisa, editable)

  Bukti Transfer (WAJIB jika Transfer Bank):
    [📷 Pilih Foto]
    Thumbnail preview setelah dipilih
    Upload progress indicator

Submit flow:
  1. Jika ada foto → POST /v1/uploads/presign
  2. PUT {uploadUrl} dengan file binary
  3. POST /v1/orders/:id/payments { amount, paymentMethod, paymentType, proofUrl }
  4. Sukses → pop + snackbar "Pembayaran dikirim, menunggu konfirmasi toko."
```

---

### 13. Review Form Screen

**Endpoint:** `POST /v1/orders/:id/reviews`

```
Pre-check:
  if order.status != completed → tidak bisa akses
  if review sudah ada → redirect ke order detail

Form:
  Nama toko (read-only)
  {brand} {model} (read-only)

  Rating:
    ⭐⭐⭐⭐⭐  tap bintang — animasi scale
    Label:  1=Sangat Buruk, 3=Biasa, 5=Sangat Bagus

  Komentar (opsional):
    TextArea, maxLength 500, counter tampil

Tombol: [Kirim Ulasan]

Sukses → Review Success Screen
Error 409 → pop + snackbar "Kamu sudah memberikan ulasan."
```

### Review Success Screen
```
Animasi Lottie confetti
"🎉 Ulasan berhasil dikirim!"
CouponRewardBanner:
  "Kupon diskon Rp10.000 sudah ditambahkan ke akunmu!"
  Kode: {coupon.code} | Berlaku s/d: {coupon.expiredAt}
  [Salin Kode]

[Lihat Kupon Saya]  [Kembali ke Pesanan]
```

---

### 14. Warranty Claim Screen

**Endpoint:** `POST /v1/orders/:id/disputes`

```dart
// Cek sebelum buka screen
if (order.warrantyExpiredAt == null ||
    DateTime.now().isAfter(order.warrantyExpiredAt!)) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Garansi Sudah Berakhir'),
      content: Text('Masa garansi berakhir pada \${_fmt(order.warrantyExpiredAt)}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
                           child: const Text('Tutup'))],
    ),
  );
  return;
}
```

```
Info garansi: "Garansi aktif s/d {warrantyExpiredAt}"

Form:
  Jenis Masalah *
    ● Klaim Garansi (default)
    ○ Kualitas Servis Tidak Sesuai
    ○ Diagnosa Salah
    ○ Lainnya

  Deskripsi Masalah * (min 20 karakter)
    TextArea

  Bukti Foto (opsional, max 5 foto):
    [+ Tambah Foto]
    Grid thumbnail, tap untuk hapus

Submit flow:
  1. Upload tiap foto → dapat evidenceUrls[]
  2. POST /v1/orders/:id/disputes
  3. Sukses → pop ke Order Detail + snackbar
     "Klaim diterima. Admin toko akan merespons dalam 24 jam."
  4. 409 DISPUTE_ALREADY_ACTIVE → "Sudah ada klaim aktif."
  5. 422 WARRANTY_EXPIRED → "Masa garansi sudah berakhir."
```

---

### 15. Profile Screen

**Endpoints:** `GET /v1/me`, `PATCH /v1/me`, `POST /v1/auth/logout`

```
Header:
  Avatar (CircleAvatar, tap untuk ganti foto → upload → PATCH /v1/me avatarUrl)
  Nama Lengkap (editable inline)
  +62xxxxxxx (read-only, label "(tidak bisa diubah)")

Form Data Diri:
  Nama Lengkap *
  Alamat

Tombol [Simpan] muncul hanya jika ada perubahan (dirty state)

Menu:
  📦 Pesanan Saya    → /orders
  🎟️ Kupon Saya      → /coupons
  🛡️ Garansi Aktif   → /warranty
  📱 Sesi Login      → /sessions
  🔐 Ganti Password  → /change-password

Tombol Logout (merah) → showDialog konfirmasi
  → POST /v1/auth/logout { refresh_token }
  → clearAll storage
  → context.go('/login')
```

---

## Riverpod Providers

```dart
// providers/auth_provider.dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => AuthState.loading();

  Future<void> init() async {
    final token = await ref.read(secureStorageProvider).getAccessToken();
    if (token == null) { state = AuthState.unauthenticated(); return; }
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AuthState.authenticated(user);
    } catch (_) {
      await ref.read(secureStorageProvider).clearAll();
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String phone, String password) async {
    state = AuthState.loading();
    try {
      final result = await ref.read(authRepositoryProvider).login(phone, password);
      await ref.read(secureStorageProvider).saveTokens(
        result.accessToken, result.refreshToken);
      state = AuthState.authenticated(
        result.user.copyWith(isFirstLogin: result.isFirstLogin));
    } catch (e) {
      state = AuthState.error(_parseError(e));
    }
  }

  Future<void> logout() async {
    final refresh = await ref.read(secureStorageProvider).getRefreshToken();
    if (refresh != null) {
      await ref.read(authRepositoryProvider).logout(refresh);
    }
    await ref.read(secureStorageProvider).clearAll();
    state = AuthState.unauthenticated();
  }
}

// providers/order_provider.dart

// List order dengan filter
@riverpod
Future<List<ServiceOrder>> customerOrders(
  CustomerOrdersRef ref, {
  String? statusGroup, // 'active' | 'completed' | 'cancelled'
  int page = 1,
}) async {
  final statusMap = {
    'active':    'waiting_device,device_received,diagnosing,' +
                  'waiting_approval,waiting_sparepart,repairing,' +
                  'quality_check,waiting_payment,disputed',
    'completed': 'completed',
    'cancelled': 'cancelled',
  };
  return ref.read(orderRepositoryProvider).getMyOrders(
    status: statusMap[statusGroup], page: page);
}

// Order detail (manual refresh dengan ref.invalidate)
@riverpod
Future<ServiceOrder> orderDetail(OrderDetailRef ref, String orderId) async {
  return ref.read(orderRepositoryProvider).getOrderDetail(orderId);
}

// Tracking dengan polling 30 detik
@riverpod
Stream<OrderProgressResponse> orderTracking(
  OrderTrackingRef ref, String orderId,
) async* {
  final repo = ref.read(orderRepositoryProvider);
  yield await repo.getOrderProgress(orderId);
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await repo.getOrderProgress(orderId);
  }
}
```

---

## Error Handling Pattern (Konsisten di Semua Screen)

```dart
// lib/core/utils/api_error_handler.dart
String parseApiError(Object error) {
  if (error is DioException) {
    final code = error.response?.data?['error']?['code'] as String?;
    final msg  = error.response?.data?['error']?['user_message'] as String?;
    return msg ?? _codeToMessage(code);
  }
  return 'Terjadi kesalahan. Coba lagi nanti.';
}

String _codeToMessage(String? code) => switch (code) {
  'INVALID_CREDENTIALS'    => 'Nomor HP atau password salah.',
  'ACCOUNT_LOCKED'         => 'Akun terkunci sementara.',
  'STOCK_UNAVAILABLE'      => 'Stok sparepart habis.',
  'COUPON_EXPIRED'         => 'Kupon sudah kadaluarsa.',
  'COUPON_NOT_OWNED'       => 'Kupon ini bukan milikmu.',
  'WARRANTY_EXPIRED'       => 'Masa garansi sudah berakhir.',
  'DISPUTE_ALREADY_ACTIVE' => 'Sudah ada klaim aktif.',
  'DUPLICATE_REVIEW'       => 'Kamu sudah memberikan ulasan.',
  _                          => 'Terjadi kesalahan. Coba lagi nanti.',
};

// Pemakaian di screen:
Future<void> _submit() async {
  setState(() => _loading = true);
  try {
    await ref.read(orderRepositoryProvider).approveOrder(widget.orderId);
    ref.invalidate(orderDetailProvider(widget.orderId));
    if (mounted) Navigator.pop(context);
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(parseApiError(e))));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

---

## GoRouter Configuration

```dart
final customerRoutes = [
  GoRoute(path: '/',              redirect: (_, __) => '/splash'),
  GoRoute(path: '/splash',        builder: (_, __) => const SplashScreen()),
  GoRoute(path: '/login',         builder: (_, __) => const LoginScreen()),
  GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
  GoRoute(path: '/home',          builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/stores',        builder: (_, __) => const StoreListScreen()),
  GoRoute(path: '/stores/:id',    builder: (_, s) =>
    StoreDetailScreen(storeId: s.pathParameters['id']!)),
  GoRoute(path: '/booking/:storeId', builder: (_, s) =>
    BookingFormScreen(storeId: s.pathParameters['storeId']!)),
  GoRoute(path: '/booking-success/:orderNumber', builder: (_, s) =>
    BookingSuccessScreen(orderNumber: s.pathParameters['orderNumber']!,
      isNewCustomer: s.extra as bool? ?? false)),
  GoRoute(path: '/orders',        builder: (_, __) => const OrderListScreen()),
  GoRoute(path: '/orders/:id',    builder: (_, s) =>
    OrderDetailScreen(orderId: s.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/tracking', builder: (_, s) =>
    TrackingScreen(orderId: s.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/payment', builder: (_, s) =>
    PaymentUploadScreen(orderId: s.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/review', builder: (_, s) =>
    ReviewFormScreen(orderId: s.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/warranty-claim', builder: (_, s) =>
    WarrantyClaimScreen(orderId: s.pathParameters['id']!)),
  GoRoute(path: '/profile',       builder: (_, __) => const ProfileScreen()),
  GoRoute(path: '/sessions',      builder: (_, __) => const SessionsScreen()),
];

// Redirect guard global
String? authRedirect(BuildContext ctx, GoRouterState state) {
  final authState = ProviderScope.containerOf(ctx).read(authNotifierProvider);
  final loc = state.matchedLocation;
  final publicRoutes = ['/', '/splash', '/login', '/change-password'];

  if (authState.isLoading) return null;
  if (!authState.isAuthenticated && !publicRoutes.contains(loc)) return '/login';
  if (authState.isFirstLogin && loc != '/change-password') return '/change-password';
  if (authState.isAuthenticated && loc == '/login') return '/home';
  return null;
}
```

---

## Acceptance Criteria

- [ ] Login berhasil dengan format HP bebas (08xxx / +62xxx / 62xxx)
- [ ] Login gagal → snackbar pesan yang tepat per error code
- [ ] isFirstLogin=true → paksa ke Change Password, semua route lain di-redirect
- [ ] Change Password sukses → ke Home
- [ ] Booking tanpa JWT (pelanggan baru) → 201, Booking Success muncul
- [ ] Booking: pre-fill nama + HP jika sudah login
- [ ] Sparepart stok 0 → disabled di selector, tidak bisa dipilih
- [ ] Preview estimasi harga update real-time
- [ ] Bukti transfer: field foto WAJIB jika metode = Transfer Bank (validasi client)
- [ ] Order List tabs Aktif / Selesai / Dibatalkan menampilkan data yang benar
- [ ] SLA < 6 jam → teks merah di list item
- [ ] DiagnosisApprovalCard tampil saat waiting_approval dengan detail biaya
- [ ] Setuju → status repairing, card hilang
- [ ] Tolak → confirm dialog → status cancelled
- [ ] Tracking poll 30 detik → timestamp "Diperbarui: HH:mm" update
- [ ] Payment upload: foto preview setelah dipilih
- [ ] Payment sukses → snackbar, kembali ke Order Detail
- [ ] Review form: bintang animasi saat tap
- [ ] Review sukses → Review Success + info kupon
- [ ] Klaim Garansi: tombol tidak muncul jika warrantyExpiredAt sudah lewat
- [ ] Upload multiple foto bukti garansi berfungsi
- [ ] Profile: nomor HP read-only
- [ ] Logout → hapus token → redirect ke Login
- [ ] `flutter analyze` 0 error
- [ ] `flutter build apk --release` sukses

---

## Output Branch

`feature/fase-2-customer` — merge ke `develop` setelah semua AC hijau.
