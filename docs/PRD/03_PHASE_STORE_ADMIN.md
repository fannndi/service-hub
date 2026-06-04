# Phase 3 — Store Admin Mobile App
**Branch:** `feature/fase-3-store-admin`
**PIC:** Anggota 2
**Estimasi:** 5–7 hari kerja
**Dependency:** Fase 1 harus sudah di-merge ke `develop`

---

## Objective

Membangun seluruh pengalaman admin toko — menerima order, diagnosa, kelola inventory, konfirmasi pembayaran, dan handle klaim garansi.

---

## Deliverables

- [ ] 10 screen selesai dan bisa di-build
- [ ] Login store_admin (endpoint BERBEDA dari customer)
- [ ] Dashboard dengan summary realtime
- [ ] Receive & update order flow (semua tombol per status)
- [ ] Credential panel untuk pelanggan baru
- [ ] Diagnosis form dengan kalkulasi harga realtime
- [ ] Konfirmasi pembayaran dengan bukti viewer
- [ ] Inventory CRUD lengkap
- [ ] Handle dispute / klaim garansi

---

## Scope

**Kerjakan:** `lib/features/store_admin/` seluruhnya + concrete repository impl.
**Jangan sentuh:** `lib/features/customer/`, `lib/core/`, `lib/shared/`.

### Perbedaan Kritis vs Customer App

| Aspek | Customer | Store Admin |
|---|---|---|
| Login endpoint | `POST /v1/auth/login` | `POST /v1/store/auth/login` |
| Storage key | `access_token` | `store_access_token` |
| JWT payload | `role: customer` | `role: store_admin` + `storeId` |
| isFirstLogin | Wajib ganti password | Wajib ganti password juga |
| Booking order | ✅ | ❌ |
| Diagnosa | ❌ | ✅ |
| Konfirmasi bayar | ❌ | ✅ |

---

## Folder Structure

```
lib/features/store_admin/
├── screens/
│   ├── auth/
│   │   ├── store_login_screen.dart
│   │   └── store_change_password_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── orders/
│   │   ├── order_list_screen.dart
│   │   └── order_detail_screen.dart
│   ├── diagnosis/diagnosis_screen.dart
│   ├── inventory/
│   │   ├── inventory_screen.dart
│   │   └── sparepart_form_screen.dart
│   ├── payments/payment_confirmation_screen.dart
│   ├── disputes/
│   │   ├── dispute_list_screen.dart
│   │   └── dispute_detail_screen.dart
│   └── settings/settings_screen.dart
├── providers/
│   ├── store_auth_provider.dart
│   ├── dashboard_provider.dart
│   ├── store_order_provider.dart
│   ├── inventory_provider.dart
│   └── dispute_provider.dart
├── repositories/
│   ├── store_auth_repository_impl.dart
│   ├── store_order_repository_impl.dart
│   ├── store_inventory_repository_impl.dart
│   └── store_dispute_repository_impl.dart
└── widgets/
    ├── credential_panel_card.dart
    ├── diagnosis_item_row.dart
    ├── inventory_item_card.dart
    ├── sla_countdown_badge.dart
    └── payment_proof_viewer.dart
```

---

## Screen Specifications

### 1. Store Login Screen

**Endpoint:** `POST /v1/store/auth/login`

```
Judul: "ServisGadget — Portal Toko"
Subtitle: "Masuk sebagai Admin Toko"

Fields:
  Nomor HP  (auto-format +62)
  Password  (toggle visibility)

Token storage — WAJIB pakai key berbeda dari customer:
  store_access_token
  store_refresh_token
  (gunakan SecureStorageService.storePrefix)

Sukses:
  Simpan store_access_token + store_refresh_token
  Simpan storeId dari response ke storage
  Jika is_first_login=true → /store/change-password
  Else                      → /store/dashboard

Error: sama dengan customer login
```

### 2. Store Change Password Screen

**Endpoint:** `POST /v1/store/auth/change-password`

Identik dengan customer change password, tapi pakai endpoint store admin dan token store admin.

---

### 3. Dashboard Screen

**Endpoint:** `GET /v1/store/dashboard/summary`

```
Layout:

Header:
  "Halo, {adminName}!"
  "{storeName}"
  ⭐ {ratingAvg} | {totalCompletedThisMonth} selesai bulan ini

Summary Grid (2x2 card, tap ke order list dengan filter):
  ┌──────────────┐ ┌──────────────┐
  │  {active}    │ │  {pending    │
  │  Aktif       │ │   Payment}   │
  │              │ │  Bayar       │
  └──────────────┘ └──────────────┘
  ┌──────────────┐ ┌──────────────┐
  │  {waiting    │ │  {disputes}  │
  │   Approval}  │ │  Klaim       │
  │  Nunggu OK   │ │  Garansi     │
  └──────────────┘ └──────────────┘

Status Breakdown (list horizontal chips):
  waiting_device: {n}  |  diagnosing: {n}  |  repairing: {n}  | ...

Quick Actions:
  [📋 Semua Order]  [📦 Inventory]  [⚙️ Pengaturan]

Auto-refresh: polling 60 detik atau pull-to-refresh
```

```dart
// providers/dashboard_provider.dart
@riverpod
Stream<DashboardSummary> dashboardSummary(DashboardSummaryRef ref) async* {
  final repo = ref.read(storeOrderRepositoryProvider);
  yield await repo.getDashboardSummary();
  await for (final _ in Stream.periodic(const Duration(seconds: 60))) {
    yield await repo.getDashboardSummary();
  }
}
```

---

### 4. Order List Screen

**Endpoint:** `GET /v1/store/orders?status=&page=&limit=20`

```
TabBar:
  [Semua Aktif] [Perlu Aksi] [Selesai] [Dibatalkan]

"Perlu Aksi" = status IN: waiting_device, diagnosing, repairing,
               quality_check, waiting_payment

Filter chips (di bawah tab, scrollable):
  Semua | Menunggu Terima | Diagnosa | Persetujuan |
  Perbaikan | QC | Bayar | Dispute

List item:
  ┌──────────────────────────────────────────────┐
  │ SG-20250812-A3F7K2         [STATUS BADGE]    │
  │ Budi Santoso · +628xxxxx                     │
  │ Samsung Galaxy S24 Ultra                     │
  │ 12 Agt 2025        [⏰ 4j 23m] ← merah jika <6j│
  └──────────────────────────────────────────────┘

SlaCountdownBadge:
  Tampil jika slaDeadline ada dan order belum terminal
  Warna: hijau(>24j) → kuning(6-24j) → merah(<6j)
  Update setiap menit

Tap → /store/orders/:id
```

---

### 5. Order Detail Screen (Admin)

**Endpoint:** `GET /v1/store/orders/:id`

```
Header: nomor order | status badge | tanggal

Section Info Pelanggan:
  Nama + nomor HP → tap icon phone → launch dialer
  Device: brand, model, jenis
  Pengiriman: metode + alamat (jika courier)

CredentialPanelCard (muncul jika credentialPanel.isNewCustomer=true
                     DAN credentialPanel.credential != null):
  ┌────────────────────────────────────────┐
  │ 👤 Pelanggan Baru — Kirim via WA       │
  │────────────────────────────────────────│
  │ HP:       +628123456789                │
  │ Password: 022104097890                 │
  │ Berlaku s/d: {expiresAt}               │
  │                                        │
  │ Salin info di atas dan kirim ke        │
  │ pelanggan via WhatsApp agar mereka     │
  │ bisa login dan tracking pesanan.       │
  │                                        │
  │ [📋 Salin Password] [✅ Sudah Dikirim] │
  └────────────────────────────────────────┘

  Jika credential = null (expired/sent):
    "✅ Kredensial sudah terkirim" (hijau)
    atau
    "⚠️ Kredensial expired — reset jika diperlukan" (kuning)

Section Item Order:
  Per item: jenis, deskripsi, sparepart, harga, status badge

Section Harga:
  Estimasi: Rp {totalEstimasi}
  Final (jika ada): Rp {finalPrice}

SLA Deadline (kuning/merah jika dekat)

Timeline Tracking (3 terbaru, "Lihat Semua")

Section Pembayaran (jika ada):
  Per payment: tanggal, nominal, metode, status
  Thumbnail bukti → tap untuk full screen (jika transfer_bank)

Action Panel (lihat state machine di bawah)
```

### CredentialPanelCard Widget

```dart
class CredentialPanelCard extends StatelessWidget {
  final CredentialPanel panel;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    if (!panel.isNewCustomer) return const SizedBox.shrink();

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.person_add, color: Colors.amber),
              const SizedBox(width: 8),
              Text("Pelanggan Baru — Kirim via WA",
                style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const Divider(),
            if (panel.credential != null) ...[
              _row("HP:",       panel.credential!.phone),
              _row("Password:", panel.credential!.password,
                style: const TextStyle(fontFamily: 'monospace',
                  fontWeight: FontWeight.bold, fontSize: 16)),
              _row("Berlaku s/d:", _fmt(panel.credential!.expiresAt)),
              const SizedBox(height: 12),
              const Text(
                "Salin info di atas dan kirim ke pelanggan via WhatsApp "
                "agar mereka bisa login dan tracking pesanan.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text("Salin Password"),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: panel.credential!.password));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password disalin!")));
                  },
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Sudah Dikirim"),
                  onPressed: () => _markSent(context),
                ),
              ]),
            ] else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text("Kredensial sudah terkirim",
                    style: TextStyle(color: Colors.green)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markSent(BuildContext context) async {
    try {
      await context.read(storeOrderRepositoryProvider)
        .markCredentialSent(orderId);
      // Invalidate order detail provider
      context.read(storeOrderDetailProvider(orderId).notifier)
        .refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parseApiError(e))));
    }
  }
}
```

### Action Panel — State Machine Tombol

```dart
Widget _buildActionPanel(ServiceOrder order) {
  return switch (order.status) {
    OrderStatus.waitingDevice => _primaryBtn(
      icon: Icons.check_circle_outline,
      label: "Konfirmasi Perangkat Diterima",
      onTap: () => _updateStatus("device_received"),
    ),

    OrderStatus.deviceReceived => _primaryBtn(
      icon: Icons.search,
      label: "Mulai Diagnosa",
      onTap: () => _updateStatus("diagnosing"),
    ),

    OrderStatus.diagnosing => _primaryBtn(
      icon: Icons.assignment,
      label: "Submit Hasil Diagnosa",
      onTap: () => context.push("/store/orders/${order.id}/diagnosis"),
    ),

    // Admin TIDAK bisa apa-apa di sini — hanya info + countdown
    OrderStatus.waitingApproval => _infoPanel(
      icon: Icons.hourglass_top,
      message: "Menunggu persetujuan pelanggan.",
      deadline: order.slaDeadline,
    ),

    OrderStatus.waitingSparepart => _primaryBtn(
      icon: Icons.inventory_2,
      label: "Sparepart Tiba — Mulai Perbaikan",
      onTap: () => _updateStatus("repairing"),
    ),

    OrderStatus.repairing => _primaryBtn(
      icon: Icons.build,
      label: "Selesai Perbaikan → Quality Check",
      onTap: () => _updateStatus("quality_check"),
    ),

    OrderStatus.qualityCheck => _primaryBtn(
      icon: Icons.verified,
      label: "Quality Check OK → Minta Pembayaran",
      color: Colors.teal,
      onTap: () => _updateStatus("waiting_payment"),
    ),

    OrderStatus.waitingPayment => _primaryBtn(
      icon: Icons.payment,
      label: "Konfirmasi Pembayaran",
      color: Colors.green,
      onTap: () => context.push("/store/orders/${order.id}/payment-confirm"),
    ),

    OrderStatus.disputed => _primaryBtn(
      icon: Icons.gavel,
      label: "Respons Klaim Garansi",
      color: Colors.orange,
      onTap: () => context.push("/store/disputes/${order.disputeId}"),
    ),

    _ => const SizedBox.shrink(),
  };
}

// ⚠️ PENTING: waiting_approval → repairing dilakukan oleh CUSTOMER via approve.
// Store admin TIDAK bisa paksa transisi ini. Jika admin menekan tombol
// apapun yang mengarah ke repairing dari waiting_approval → larang di sisi client.
```

---

### 6. Diagnosis Screen

**Endpoint:** `PATCH /v1/store/orders/:id/diagnosis`

```
Konteks: order.status harus "diagnosing"

Catatan Diagnosa Umum (opsional):
  TextArea

Per Item Order (loop):
  ┌──────────────────────────────────────┐
  │ Item {n}: {serviceType}              │
  │ {complaint}                          │
  │ Sparepart asal: {sparepartName}      │
  │                                      │
  │ Status *:                            │
  │   ● Dikerjakan (confirmed)           │
  │   ○ Ganti Sparepart (replaced)       │
  │   ○ Tidak Dikerjakan (cancelled)     │
  │                                      │
  │ [Jika "Ganti Sparepart"]:            │
  │   Pilih Sparepart Pengganti *        │
  │   (dropdown dari inventory toko)     │
  │   ⚠️ Wajib diisi jika status=replaced│
  │                                      │
  │ Harga Item (Rp) *:                   │
  │   [number input, min 0]              │
  │                                      │
  │ Catatan Teknisi (opsional):          │
  │   [text input]                       │
  └──────────────────────────────────────┘

Service Fee (Rp) *:
  (pre-fill dari store.config.service_fee[serviceType])

──────────────────────────────────────
Preview Total (update realtime):
  Subtotal items:   Rp {sum confirmed+replaced finalItemPrice}
  Service Fee:      Rp {serviceFee}
  ─────────────────────────────────────
  Final Price:      Rp {total}
──────────────────────────────────────

[Submit Diagnosa & Kirim ke Pelanggan]

Validasi sebelum submit:
  - Minimal 1 item status != cancelled
  - Jika status=replaced → replacedSparepartId wajib diisi
  - serviceFee >= 0
  - Semua item harus punya finalItemPrice >= 0
```

```dart
// Kalkulasi realtime
double get _totalFinalPrice {
  double total = _serviceFee;
  for (final item in _diagnosisItems) {
    if (item.status != "cancelled") {
      total += item.finalItemPrice;
    }
  }
  return total;
}

// Submit
Future<void> _submit() async {
  // Validasi replaced
  for (final item in _diagnosisItems) {
    if (item.status == "replaced" && item.replacedSparepartId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          "Pilih sparepart pengganti untuk item yang diganti.")));
      return;
    }
  }

  setState(() => _loading = true);
  try {
    await ref.read(storeOrderRepositoryProvider).submitDiagnosis(
      orderId: widget.orderId,
      dto: SubmitDiagnosisRequest(
        diagnosisNote: _noteController.text.isEmpty ? null : _noteController.text,
        serviceFee:    _serviceFee,
        items:         _diagnosisItems,
      ),
    );
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          "Diagnosa berhasil dikirim ke pelanggan.")));
    }
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(parseApiError(e))));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

---

### 7. Inventory Screen

**Endpoint:** `GET /v1/store/spareparts`

```
Header Stats Bar:
  Total Aktif: {n}  |  Stok Rendah: {n}  |  Habis: {n}

Filter Chips:
  Brand | Tipe Part | Status

List item (InventoryItemCard):
  ┌────────────────────────────────────────────────┐
  │ LCD Samsung S24 Ultra Original                 │
  │ Samsung · Galaxy S24 Ultra · Layar             │
  │ Rp 800.000                                     │
  │                                                │
  │ Total: 5 | Reserved: 2 | Tersedia: 3           │
  │ [⚠️ Stok Rendah] ← merah jika tersedia <= threshold│
  │                           [✏️ Edit] [🗑️ Hapus] │
  └────────────────────────────────────────────────┘

FAB: [+ Tambah Sparepart] → /store/inventory/new

Hapus:
  showDialog konfirmasi
  Jika backend return 422 → snackbar "Sparepart masih dipakai di pesanan aktif."
```

---

### 8. Sparepart Form Screen

**Endpoint:** `POST /v1/store/spareparts` (tambah) / `PATCH /v1/store/spareparts/:id` (edit)

```
Form Fields:

Brand *:
  TextFormField

Model Device *:
  TextFormField

Tipe Part *:
  DropdownButtonFormField
  Options:
    screen_replacement  → Layar / LCD
    battery_replacement → Baterai
    charging_port       → Port Charging
    camera              → Kamera
    other               → Lainnya

Nama Sparepart *:
  TextFormField (deskriptif, contoh: "LCD Samsung S24 Ultra Original")

Harga (Rp) *:
  TextFormField, keyboard: number, min 0

Stok *:
  TextFormField, keyboard: number, min 0
  (Edit mode: tampilkan juga info "Reserved: {n}, Tersedia: {qty-reserved}")

Status *:
  DropdownButtonFormField
  Options:
    available    → Tersedia
    preorder     → Pre-order
    discontinued → Tidak Dijual Lagi

[Simpan]

Validasi:
  Semua field * tidak boleh kosong
  Harga >= 0
  Stok >= 0 (bukan negatif)
```

---

### 9. Payment Confirmation Screen

**Endpoint:** `POST /v1/store/orders/:id/payments/:pid/confirm`

```
Header:
  Order: {orderNumber}
  Pelanggan: {customerName}
  Final Price: Rp {finalPrice}

Riwayat Pembayaran (list):
  Per payment:
    Tanggal & jam
    {paymentType}: {paymentMethod}
    Nominal: Rp {amount}
    Status: [Menunggu Konfirmasi] / [Dikonfirmasi] / [Ditolak]
    
    Jika ada proofUrl (transfer_bank):
      Thumbnail foto → tap untuk PaymentProofViewer (full screen + zoom)
    
    Jika status=pending:
      [✅ Konfirmasi Pembayaran]  [❌ Tolak Bukti]

PaymentProofViewer:
  InteractiveViewer (support zoom + pan)
  Tombol Download / Close

Konfirmasi:
  showDialog: "Konfirmasi pembayaran Rp {amount}?"
  → POST /v1/store/orders/:id/payments/:pid/confirm
  → Sukses: pop + snackbar "Pembayaran dikonfirmasi!
    Garansi aktif {warrantyDays} hari s/d {warrantyExpiredAt}"
  
Tolak:
  showDialog dengan TextFormField alasan (min 10 karakter)
  → PATCH payment status ke failed
  → Pelanggan bisa upload ulang
```

---

### 10. Dispute List Screen

**Endpoint:** `GET /v1/store/disputes`

```
TabBar: [Perlu Respons] [Sudah Direspons] [Semua]

"Perlu Respons" = status = open

List item:
  ┌───────────────────────────────────────────────┐
  │ SG-20250812-A3F7K2   [KLAIM GARANSI]  [OPEN] │
  │ Budi Santoso                                  │
  │ "Layar retak lagi dari dalam setelah 2 minggu"│
  │ 20 Agt 2025    Sisa waktu: 18j 42m (merah)   │
  └───────────────────────────────────────────────┘

Tap → /store/disputes/:id
```

---

### 11. Dispute Detail Screen

**Endpoint:** `GET /v1/store/disputes/:id`, `POST /v1/store/disputes/:id/respond`

```
Order Asal: {orderNumber}
Pelanggan: {customerName}
Tanggal servis: {completedAt}

Tipe Klaim: {disputeType label}

Deskripsi:
  "{description}"

Bukti Foto:
  Grid thumbnail (jika evidenceUrls ada)
  Tap → full screen viewer

Garansi berlaku: s/d {warrantyExpiredAt}
  (tampilkan "masih berlaku" hijau / "sudah berakhir" merah)

SLA Respons:
  Sisa waktu: {countdown} [merah jika < 6 jam]

──────────────────────────────────────────
Form Respons (hanya jika status = open):

Keputusan *:
  ● Terima — akan buat order perbaikan ulang (gratis)
  ○ Tolak  — berikan alasan

Catatan / Alasan * (min 10 karakter):
  TextArea

[Kirim Respons]
──────────────────────────────────────────

Terima → POST /v1/store/disputes/:id/respond
  { decision: "store_accepted", storeResponse: "..." }
  → Sukses: pop + snackbar
    "Klaim diterima. Order garansi baru dibuat untuk pelanggan."
  → Backend buat warranty order baru (finalPrice=0)

Tolak → POST /v1/store/disputes/:id/respond
  { decision: "store_rejected", storeResponse: "..." }
  → Sukses: pop + snackbar "Klaim ditolak. Pelanggan dinotifikasi."
```

---

### 12. Settings Screen

**Endpoints:** `GET /v1/store/profile`, `PATCH /v1/store/profile`

```
Informasi Toko:
  Nama Toko *
  Alamat *
  Nomor HP Toko *

Jam Operasional:
  Per hari (Senin-Minggu):
    Toggle Buka/Tutup
    Jika Buka: jam buka - jam tutup (TimePicker)

Konfigurasi Servis:
  Service Fee Layar:      Rp [______]
  Service Fee Baterai:    Rp [______]
  Service Fee Port:       Rp [______]
  Service Fee Lainnya:    Rp [______]
  Diagnosis Fee:          Rp [______]
  Hari Garansi:           [30] hari
  Threshold Stok Rendah:  [2] unit
  Deposit Wajib:          [toggle]

Akun:
  [Ganti Password]  → /store/change-password
  [Logout]          → confirm → clearAll → /store/login

Tombol [Simpan Perubahan] (muncul jika ada perubahan dirty state)
```

---

## Riverpod Providers

```dart
// providers/store_auth_provider.dart
@riverpod
class StoreAuthNotifier extends _$StoreAuthNotifier {
  @override
  StoreAuthState build() => StoreAuthState.initial();

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(storeAuthRepositoryProvider)
        .login(phone, password);
      // Key BERBEDA: store_access_token bukan access_token
      await ref.read(storeStorageProvider).saveTokens(
        result.accessToken, result.refreshToken);
      await ref.read(storeStorageProvider).saveStoreId(
        result.storeAdmin.storeId);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        isFirstLogin: result.isFirstLogin,
        storeAdmin: result.storeAdmin,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: parseApiError(e));
    }
  }

  Future<void> logout() async {
    final refresh = await ref.read(storeStorageProvider).getRefreshToken();
    if (refresh != null) {
      await ref.read(storeAuthRepositoryProvider).logout(refresh);
    }
    await ref.read(storeStorageProvider).clearAll();
    state = StoreAuthState.initial();
  }
}

// providers/store_order_provider.dart
@riverpod
Future<List<ServiceOrder>> storeOrders(
  StoreOrdersRef ref, {
  String? statusFilter,
  int page = 1,
}) async {
  return ref.read(storeOrderRepositoryProvider)
    .getOrders(status: statusFilter, page: page);
}

@riverpod
Future<ServiceOrder> storeOrderDetail(
  StoreOrderDetailRef ref,
  String orderId,
) async {
  return ref.read(storeOrderRepositoryProvider).getOrderDetail(orderId);
}

// providers/inventory_provider.dart
@riverpod
Future<List<SparePart>> storeInventory(StoreInventoryRef ref) async {
  return ref.read(storeInventoryRepositoryProvider).getSpareparts();
}
```

---

## Repository Implementations

```dart
// repositories/store_auth_repository_impl.dart
class StoreAuthRepositoryImpl implements StoreAuthRepository {
  final Dio _dio; // Dio dengan store_access_token di interceptor

  @override
  Future<StoreLoginResult> login(String phone, String password) async {
    final resp = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
      .post("/store/auth/login",
        data: {"phone_number": phone, "password": password});
    return StoreLoginResult.fromJson(resp.data["data"]);
  }

  @override
  Future<void> markCredentialSent(String orderId) async {
    await _dio.post("/store/orders/$orderId/credential/mark-sent");
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status,
      {String? note}) async {
    await _dio.patch("/store/orders/$orderId/status",
      data: {"status": status, if (note != null) "note": note});
  }

  @override
  Future<void> submitDiagnosis(String orderId,
      SubmitDiagnosisRequest dto) async {
    await _dio.patch("/store/orders/$orderId/diagnosis",
      data: dto.toJson());
  }

  @override
  Future<Map<String, dynamic>> confirmPayment(String orderId,
      String paymentId, {String? note}) async {
    final resp = await _dio.post(
      "/store/orders/$orderId/payments/$paymentId/confirm",
      data: {if (note != null) "note": note});
    return resp.data["data"] as Map<String, dynamic>;
  }
}
```

---

## GoRouter (Store Admin)

```dart
final storeAdminRoutes = [
  GoRoute(path: "/store",
    redirect: (_, __) => "/store/login"),
  GoRoute(path: "/store/login",
    builder: (_, __) => const StoreLoginScreen()),
  GoRoute(path: "/store/change-password",
    builder: (_, __) => const StoreChangePasswordScreen()),
  GoRoute(path: "/store/dashboard",
    builder: (_, __) => const DashboardScreen()),
  GoRoute(path: "/store/orders",
    builder: (_, __) => const OrderListScreen()),
  GoRoute(path: "/store/orders/:id",
    builder: (_, s) =>
      OrderDetailScreen(orderId: s.pathParameters["id"]!)),
  GoRoute(path: "/store/orders/:id/diagnosis",
    builder: (_, s) =>
      DiagnosisScreen(orderId: s.pathParameters["id"]!)),
  GoRoute(path: "/store/orders/:id/payment-confirm",
    builder: (_, s) =>
      PaymentConfirmationScreen(orderId: s.pathParameters["id"]!)),
  GoRoute(path: "/store/inventory",
    builder: (_, __) => const InventoryScreen()),
  GoRoute(path: "/store/inventory/new",
    builder: (_, __) => const SparepartFormScreen()),
  GoRoute(path: "/store/inventory/:id/edit",
    builder: (_, s) =>
      SparepartFormScreen(sparepartId: s.pathParameters["id"])),
  GoRoute(path: "/store/disputes",
    builder: (_, __) => const DisputeListScreen()),
  GoRoute(path: "/store/disputes/:id",
    builder: (_, s) =>
      DisputeDetailScreen(disputeId: s.pathParameters["id"]!)),
  GoRoute(path: "/store/settings",
    builder: (_, __) => const SettingsScreen()),
];

String? storeAuthRedirect(BuildContext ctx, GoRouterState state) {
  final auth = ProviderScope.containerOf(ctx)
    .read(storeAuthNotifierProvider);
  final loc = state.matchedLocation;
  final publicRoutes = ["/store", "/store/login", "/store/change-password"];

  if (auth.isLoading) return null;
  if (!auth.isLoggedIn && !publicRoutes.contains(loc)) return "/store/login";
  if (auth.isFirstLogin && loc != "/store/change-password")
    return "/store/change-password";
  if (auth.isLoggedIn && loc == "/store/login") return "/store/dashboard";
  return null;
}
```

---

## Acceptance Criteria

### Auth
- [ ] Login store admin sukses → token disimpan dengan key `store_access_token`
- [ ] Store token tidak bisa digunakan di customer endpoint → 403
- [ ] isFirstLogin=true → paksa ke Change Password
- [ ] Logout → hapus semua store token → redirect ke /store/login

### Dashboard
- [ ] Summary card menampilkan angka yang benar
- [ ] Tap summary card → order list dengan filter status yang sesuai
- [ ] Auto-refresh 60 detik berjalan

### Order Management
- [ ] Order list hanya menampilkan order milik toko ini
- [ ] SlaCountdownBadge update tiap menit, merah jika < 6 jam
- [ ] CredentialPanelCard muncul untuk pelanggan baru yang credential-nya belum expired
- [ ] Tombol "Salin Password" → clipboard
- [ ] Tombol "Sudah Dikirim" → credentialPlainEnc=null di DB, panel berubah
- [ ] Tombol aksi sesuai status (lihat state machine di spec)
- [ ] waiting_approval → TIDAK ada tombol aksi untuk admin
- [ ] Update status device_received, diagnosing, waiting_sparepart, repairing, quality_check, waiting_payment → OK
- [ ] PATCH status=completed langsung → 422 (tombol ini tidak ada di UI)

### Diagnosis
- [ ] Form menampilkan semua item dari order
- [ ] Status "replaced" → dropdown sparepart pengganti muncul, wajib diisi
- [ ] Status "replaced" tanpa pilih sparepart → validasi gagal, tidak bisa submit
- [ ] Total harga update realtime saat input berubah
- [ ] finalPrice = SUM(confirmed+replaced items) + serviceFee
- [ ] Submit sukses → order status=waiting_approval, snackbar "Dikirim ke pelanggan"

### Payment
- [ ] Thumbnail bukti foto tampil
- [ ] Tap thumbnail → full screen viewer dengan zoom support
- [ ] Konfirmasi pembayaran → order completed, snackbar info garansi
- [ ] warrantyDays dan warrantyExpiredAt benar setelah confirm

### Inventory
- [ ] List menampilkan stok fisik, reserved, tersedia
- [ ] Stok tersedia <= threshold → badge "Stok Rendah"
- [ ] Tambah sparepart baru → muncul di list
- [ ] Edit harga/stok → tersimpan
- [ ] Hapus dengan konfirmasi → hapus dari list
- [ ] Hapus sparepart di order aktif → 422, snackbar pesan

### Dispute
- [ ] Dispute list hanya milik toko ini
- [ ] Countdown respons merah jika < 6 jam
- [ ] Terima dispute → warranty order dibuat, pelanggan dinotifikasi
- [ ] Tolak dispute → alasan wajib min 10 karakter

### Technical
- [ ] `flutter analyze` 0 error, 0 warning
- [ ] `flutter build apk --release` sukses
- [ ] Tidak ada `print()` di production code

---

## Output Branch

`feature/fase-3-store-admin` — merge ke `develop` setelah semua AC hijau.
