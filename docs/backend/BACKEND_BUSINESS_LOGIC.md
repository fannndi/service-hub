# Backend Business Logic

> Dokumentasi lengkap semua logic bisnis di backend ServisGadget.

---

## Table of Contents

1. [Order Lifecycle](#1-order-lifecycle)
2. [State Machine](#2-state-machine)
3. [SLA System](#3-sla-system)
4. [Payment Flow](#4-payment-flow)
5. [Review & Coupon Reward](#5-review--coupon-reward)
6. [Dispute & Warranty](#6-dispute--warranty)
7. [Sparepart Inventory](#7-sparepart-inventory)
8. [Store Matching Engine](#8-store-matching-engine)
9. [Notification System](#9-notification-system)

---

## 1. Order Lifecycle

### Complete Flow

```
1. Customer buat order (POST /orders)
   Status: waiting_device
   SLA: 24 jam (device harus diterima)

2. Store terima device
   Status: device_received
   Action: PATCH /store/orders/:id/status { status: "device_received" }

3. Store mulai diagnosis
   Status: diagnosing
   Action: PATCH /store/orders/:id/status { status: "diagnosing" }

4. Store submit diagnosis (POST /store/orders/:id/diagnosis)
   Status: waiting_approval
   Store isi: estimatedDays, note, items[] dengan itemPrice
   totalEstimasi dihitung dari sum(itemPrice)

5. Customer setujui/tolak diagnosis
   Approve → status: waiting_sparepart
   Reject → status: cancelled

6. Store mulai perbaikan
   Status: repairing
   sparepart stock di-reserve (qtyReserved += qty)

7. QC selesai
   Status: quality_check

8. Customer bayar
   Status: waiting_payment
   finalPrice = totalEstimasi - discountAmount + serviceFee

9. Store konfirmasi pembayaran
   Status: completed
   Set warrantyExpiredAt (30 hari)
   Increment totalCompleted store
```

### Order Creation Logic

```typescript
async createOrder(userId: string | null, dto: CreateOrderDto) {
  // dto: { storeId, deviceType, brand, deviceModel, deliveryMethod,
  //        customerName, phoneNumber, couponCode?, items[] }

  // 1. Validasi store aktif
  // 2. Auto-create account jika user baru (stealth account)
  //    - generatePassword(fullName, phone)
  //    - encryptCredential(plainPassword)
  // 3. Reserve sparepart stock (qtyReserved += 1 per item)
  // 4. Validate coupon jika ada
  // 5. Create order + items dalam transaction
  // 6. Create shipment jika courier_pickup
  // 7. Kirim WhatsApp notification
}
```

**Coupon Validation:**
- Harus valid (`isUsed = false`, `expiredAt > now()`)
- Harus milik user ini
- Potongan: `discountAmount = coupon.amount`

**Stock Reservation:**
```typescript
// Untuk setiap item dengan sparepartId:
await tx.sparePart.update({
  where: { id: sparepartId },
  data: { qtyReserved: { increment: 1 } }
});
```

---

## 2. State Machine

### Valid Transitions

```typescript
const VALID_TRANSITIONS: Record<string, string[]> = {
  waiting_device:      ['device_received', 'cancelled'],
  device_received:     ['diagnosing', 'cancelled'],
  diagnosing:          ['waiting_approval', 'cancelled'],
  waiting_approval:    ['repairing', 'waiting_sparepart', 'cancelled'],
  waiting_sparepart:   ['repairing', 'cancelled'],
  repairing:           ['quality_check', 'cancelled'],
  quality_check:       ['waiting_payment', 'cancelled'],
  waiting_payment:     ['completed', 'cancelled'],
  completed:           ['disputed'],
  cancelled:           [],
  disputed:            ['completed'],
};
```

### Transition Validation

```typescript
function assertValidTransition(from: string, to: string): void {
  if (!VALID_TRANSITIONS[from]?.includes(to)) {
    throw new InvalidStatusTransitionException(from, to);
  }
}
```

### Store-Specific Action Map

```typescript
const ACTION_STATUS_MAP: Record<string, string> = {
  receive_device:      'device_received',
  start_diagnosis:     'diagnosing',
  start_repair:        'repairing',
  sparepart_arrived:   'repairing',
  complete_repair:     'quality_check',
  start_qc:            'quality_check',
  qc_ok:               'waiting_payment',
  request_payment:     'waiting_payment',
  mark_complete:       'completed',
};
```

---

## 3. SLA System

### SLA Timeouts

| Event | Timeout | Default | Env Variable |
|-------|---------|---------|--------------|
| Device Reception | 24 jam | 1440 menit | `SLA_RECEIVE_DEVICE_MINUTES` |
| Diagnosis | 24 jam | 1440 menit | `SLA_DIAGNOSIS_MINUTES` |
| Approval | 24 jam | 1440 menit | `SLA_APPROVAL_MINUTES` |
| Payment | 48 jam | 2880 menit | `SLA_PAYMENT_MINUTES` |
| Credential Clear | 24 jam | 1440 menit | `SLA_CREDENTIAL_CLEAR_MINUTES` |
| Dispute Response | 24 jam | 1440 menit | `SLA_DISPUTE_RESPOND_MINUTES` |

### SLA Monitoring

```
@Cron('*/5 * * * *') // Setiap 5 menit
async handleSlaMonitoring() {
  // 1. Cari order dengan status aktif
  // 2. Jika slaDeadline < now():
  //    - Kirim WhatsApp warning (jika belum warned)
  //    - Increment slaBreachCount
  //    - Update slaWarnedAt
}
```

### SLA Deadline Setting
- Saat order dibuat: `slaDeadline = now + RECEIVE_DEVICE`
- Saat status berubah: `slaDeadline = now + SLA_FOR_NEW_STATUS`

---

## 4. Payment Flow

### Create Payment (Customer)

```
Customer → POST /payments/:orderId
  ↓
1. Validasi order exists & milik user
2. Validasi order dalam status yang benar
3. Jika transfer_bank → wajib ada proofUrl
4. Create Payment record (status: pending)
5. Return { paymentId, status: "pending" }
```

### Confirm Payment (Store Admin)

```
Store Admin → POST /store/payments/:orderId/:paymentId/confirm
  ↓
1. Validasi order & payment
2. Dalam transaction:
   - Update payment: status → confirmed, confirmedBy, confirmedAt
   - Update order: status → completed, paymentStatus → paid
   - Set warrantyExpiredAt = now + 30 hari
   - Increment store.totalCompleted
3. Kirim WhatsApp notification
```

### Payment Types
- `deposit`: Uang muka (tidak langsung complete order)
- `final_payment`: Pelunasan (complete order)
- `refund`: Pengembalian dana

---

## 5. Review & Coupon Reward

### Create Review

```
Customer → POST /reviews/:orderId
  ↓
1. Validasi order completed & milik user
2. Cek belum ada review (duplicate check)
3. Dalam transaction:
   - Create review (rating 1-5)
   - Create coupon reward:
     - code: "RWD-" + random 4 char
     - amount: Rp 10.000
     - expiredAt: now + 30 hari
   - Update store.ratingAvg (hitung ulang)
4. Return { reviewId, couponCode }
```

### Rating Update Formula

```typescript
// Ambil semua reviews untuk store ini
const reviews = await tx.review.findMany({ where: { storeId } });
const avg = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
await tx.store.update({
  where: { id: storeId },
  data: { ratingAvg: avg }
});
```

### Coupon Usage
- Coupon bisa dipakai saat buat order baru
- `discountAmount = coupon.amount`
- `coupon.isUsed = true`, `coupon.usedOnOrderId = orderId`

---

## 6. Dispute & Warranty

### Create Dispute

```
Customer → POST /disputes/:orderId
  ↓
1. Validasi order completed & milik user
2. Cek warranty masih berlaku (warrantyExpiredAt > now)
3. Cek belum ada dispute aktif (status ≠ open)
4. Dalam transaction:
   - Create dispute (status: open, slaDeadline: now + 24 jam)
   - Update order status → disputed
   - Create tracking entry
5. Kirim WhatsApp ke store: "Klaim garansi masuk"
```

### Respond Dispute (Store Admin)

```
Store Admin → POST /store/disputes/:id/respond
  ↓
1. Validasi dispute open & milik store
2. Dalam transaction:
   Jika diterima (store_accepted):
     - Create warranty order baru (SG-{date}-{nid})
       - isWarrantyOrder: true
       - parentOrderId: order asli
       - totalEstimasi: 0
       - finalPrice: 0
       - Items: copy dari order asli (status confirmed/replaced)
       - SLA: 24 jam
     - Create tracking untuk warranty order
     - Update order asli → completed
     - Link dispute → warrantyOrderId
   Jika ditolak (store_rejected):
     - Update dispute status saja
3. Kirim WhatsApp ke customer
```

---

## 7. Sparepart Inventory

### Stock Management

```typescript
// Qty Available = qty - qtyReserved

// Saat order dibuat:
await tx.sparePart.update({
  where: { id },
  data: { qtyReserved: { increment: 1 } }
});

// Saat order completed/cancelled:
await tx.sparePart.update({
  where: { id },
  data: { qtyReserved: { decrement: 1 } }
});
```

### CRUD Operations

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/store/spareparts` | GET | Store Admin | List spareparts (paginated) |
| `/store/spareparts` | POST | Store Admin | Create sparepart |
| `/store/spareparts/:id` | PATCH | Store Admin | Update sparepart |
| `/store/spareparts/:id` | DELETE | Store Admin | Delete sparepart |
| `/stores/:id/spareparts` | GET | Public | Browse sparepart toko |

---

## 8. Store Matching Engine

### Flow

```
Customer → GET /stores/match?brand=Samsung&deviceModel=Galaxy S23&partType=LCD
  ↓
1. Cari semua spareparts yang match:
   - brand = Samsung
   - deviceModel = Galaxy S23
   - partType = LCD
   - qty - qtyReserved > 0
   - status = 'available'
2. Group by storeId
3. Untuk setiap store:
   - Hitung totalEstimate = sum(harga sparepart) + serviceFee
   - Hitung ratingAvg
4. Sort by: ratingAvg DESC, totalEstimate ASC
5. Return results
```

### Response Format

```json
[{
  "storeId": "uuid",
  "storeName": "Service Center ABC",
  "address": "Jl. Sudirman 10",
  "ratingAvg": 4.5,
  "matchingParts": [{
    "id": "uuid",
    "partName": "LCD Samsung Galaxy S23",
    "price": 1500000,
    "qty": 5,
    "availableQty": 3
  }],
  "estimatedServiceFee": 50000,
  "totalEstimate": 1550000
}]
```

---

## 9. Notification System

### WhatsApp Gateway (Fonnte)

```typescript
@Injectable()
export class NotificationsService {
  async send(phoneNumber: string, message: string, messageType: string) {
    try {
      await this.httpService.post(
        process.env.WA_GATEWAY_URL,
        { to: phoneNumber, message },
        { headers: { Authorization: `Bearer ${process.env.WA_GATEWAY_TOKEN}` } }
      );
    } catch (error) {
      // Simpan ke failed_notifications untuk retry
      await this.prisma.failedNotification.create({
        data: { recipientType: 'customer', recipientId: phoneNumber, messageType, payload: { message }, lastError: error.message }
      });
    }
  }
}
```

### Notification Events

| Event | Message | Recipient |
|-------|---------|-----------|
| Order created | `✅ Order {number} berhasil dibuat. Status: Menunggu perangkat.` | Customer |
| Status change | `🔄 Order {number} status berubah menjadi: {status}` | Customer |
| Diagnosis ready | `🔍 Diagnosis untuk order {number} sudah selesai.` | Customer |
| Dispute created | `⚠️ Klaim garansi masuk untuk order {number}.` | Store |
| Dispute accepted | `✅ Klaim garansimu diterima!` | Customer |
| Dispute rejected | `❌ Klaim garansimu ditolak. Alasan: {reason}` | Customer |

### Failed Notification Retry
- Background job retry setiap 5 menit
- `attemptCount` di-increment setiap retry
- `lastError` diupdate
