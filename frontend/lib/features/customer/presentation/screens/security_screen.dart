import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class SecurityScreen extends StatelessWidget {

}
      );
                'Sesi aktif saat ini. Logout dari profil untuk menghapus sesi.')),
            subtitle: Text(
            title: Text('Perangkat ini'),
            leading: Icon(Icons.phone_android),
        child: ListTile(
        title: 'Sesi Login',
  Widget build(BuildContext context) => const CustomerScaffold(
  @override
  const SessionsScreen({super.key});
class SessionsScreen extends StatelessWidget {

}
  }
    );
      ),
        error: (_, __) => const EmptyMessage('Preferensi belum bisa dimuat.'),
        loading: () => const Center(child: CircularProgressIndicator()),
            }),
              ref.invalidate(notificationPreferenceProvider);
                  .saveNotificationPreference(next);
                  .read(customerSessionProvider)
              await ref
            onChanged: (next) async {
            value: value,
            title: const Text('Notifikasi WhatsApp dan aplikasi'),
        data: (value) => SwitchListTile(
      child: enabled.when(
      title: 'Preferensi Notifikasi',
    return CustomerScaffold(
    final enabled = ref.watch(notificationPreferenceProvider);
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  const NotificationPreferencesScreen({super.key});
class NotificationPreferencesScreen extends ConsumerWidget {

}
                ])));
                  Text(item!.message)
                  const SizedBox(height: 12),
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(item!.title,
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ? const EmptyMessage('Notifikasi tidak ditemukan.')
          child: item == null
          padding: const EdgeInsets.all(16),
      child: Padding(
      title: 'Detail Notifikasi',
  Widget build(BuildContext context) => CustomerScaffold(
  @override
  final NotificationItem? item;
  const NotificationDetailScreen({super.key, this.item});
class NotificationDetailScreen extends StatelessWidget {

}
      );
                        .toList())),
                                extra: item)))
                                '/notifications/${item.id}',
                            onTap: () => context.push(
                            subtitle: Text(item.message),
                            title: Text(item.title),
                                : Icons.mark_email_unread),
                                ? Icons.mark_email_read
                            leading: Icon(item.isRead
                        .map((item) => ListTile(
                    children: items
                : ListView(
                ? const EmptyMessage('Belum ada notifikasi.')
            builder: (items) => items.isEmpty
            value: ref.watch(notificationsProvider),
        child: AsyncPage(
        title: 'Notifikasi',
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
  @override
  const NotificationsScreen({super.key});
class NotificationsScreen extends ConsumerWidget {

}
      );
                        .toList())),
                        .map((coupon) => CouponRewardBanner(coupon: coupon))
                    children: items
                    padding: const EdgeInsets.all(16),
                : ListView(
                ? const EmptyMessage('Belum ada kupon.')
            builder: (items) => items.isEmpty
            value: ref.watch(couponsProvider),
        child: AsyncPage(
        title: 'Kupon Saya',
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
  @override
  const CouponsScreen({super.key});
class CouponsScreen extends ConsumerWidget {

}
  const SimpleListScreens._();
class SimpleListScreens {

}
  }
    );
      ]),
            }),
              if (context.mounted) context.go('/login');
              await ref.read(customerAuthProvider.notifier).logout();
            onTap: () async {
            iconColor: Colors.red,
            textColor: Colors.red,
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
        ListTile(
            onTap: () => context.push('/sessions')),
            title: const Text('Sesi Login'),
            leading: const Icon(Icons.devices),
        ListTile(
            onTap: () => context.push('/change-password')),
            title: const Text('Ganti Password'),
            leading: const Icon(Icons.lock),
        ListTile(
            onTap: () => context.push('/notification-preferences')),
            title: const Text('Preferensi Notifikasi'),
            leading: const Icon(Icons.notifications),
        ListTile(
            onTap: () => context.push('/coupons')),
            title: const Text('Kupon Saya'),
            leading: const Icon(Icons.local_offer),
        ListTile(
            onTap: () => context.push('/orders')),
            title: const Text('Pesanan Saya'),
            leading: const Icon(Icons.inventory),
        ListTile(
        const Divider(),
              onPressed: _loading ? null : _save, child: const Text('Simpan')),
          FilledButton(
        if (_dirty)
            onChanged: (_) => setState(() => _dirty = true)),
                labelText: 'Alamat', border: OutlineInputBorder()),
            decoration: const InputDecoration(
            maxLines: 4,
            minLines: 2,
            controller: _address,
        TextFormField(
        const SizedBox(height: 12),
                border: OutlineInputBorder())),
                labelText: 'Nomor HP (tidak bisa diubah)',
            decoration: const InputDecoration(
            readOnly: true,
            initialValue: user?.phoneNumber ?? '-',
        TextFormField(
        const SizedBox(height: 12),
            onChanged: (_) => setState(() => _dirty = true)),
                labelText: 'Nama Lengkap', border: OutlineInputBorder()),
            decoration: const InputDecoration(
            controller: _name,
        TextFormField(
        const SizedBox(height: 16),
                : 'S')),
                ? user!.fullName[0]
            child: Text((user?.fullName.isNotEmpty ?? false)
            radius: 44,
        CircleAvatar(
      child: ListView(padding: const EdgeInsets.all(16), children: [
      title: 'Profil',
    return CustomerScaffold(
    }
      _address.text = user.address ?? '';
      _name.text = user.fullName;
    if (user != null && !_dirty && _name.text.isEmpty) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      setState(() => _dirty = false);
          .updateProfile(fullName: _name.text, address: _address.text);
          .read(customerAuthProvider.notifier)
      await ref
    try {
    setState(() => _loading = true);
  Future<void> _save() async {

  bool _loading = false;
  bool _dirty = false;
  final _address = TextEditingController();
  final _name = TextEditingController();
class _ProfileScreenState extends ConsumerState<ProfileScreen> {

}
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
  @override
  const ProfileScreen({super.key});
class ProfileScreen extends ConsumerStatefulWidget {

}
  }
    );
          }),
            ]);
                  child: Text(_loading ? 'Mengirim...' : 'Kirim Klaim')),
                  onPressed: _loading ? null : _submit,
              FilledButton(
              const SizedBox(height: 20),
                      .toList()),
                          onDeleted: () => setState(() => _files.remove(file))))
                          label: Text(file.name),
                      .map((file) => InputChip(
                  children: _files
                  spacing: 8,
              Wrap(
                  label: const Text('Tambah Foto')),
                  icon: const Icon(Icons.add_a_photo),
                        },
                            setState(() => _files.add(picked));
                          if (picked != null)
                              maxWidth: 1600);
                              imageQuality: 72,
                              source: ImageSource.gallery,
                          final picked = await ImagePicker().pickImage(
                      : () async {
                      ? null
                  onPressed: _files.length >= 5
              OutlinedButton.icon(
              const SizedBox(height: 12),
                      border: OutlineInputBorder())),
                      labelText: 'Deskripsi Masalah',
                  decoration: const InputDecoration(
                  maxLines: 7,
                  minLines: 4,
                  controller: _description,
              TextField(
                  onChanged: (v) => setState(() => _type = v!)),
                  ],
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                        child: Text('Diagnosa Salah')),
                        value: 'wrong_diagnosis',
                    DropdownMenuItem(
                        child: Text('Kualitas Servis')),
                        value: 'service_quality',
                    DropdownMenuItem(
                        value: 'warranty_claim', child: Text('Klaim Garansi')),
                    DropdownMenuItem(
                  items: const [
                  decoration: const InputDecoration(labelText: 'Jenis Masalah'),
                  initialValue: _type,
              DropdownButtonFormField(
              Text('Garansi aktif s/d ${shortDate(data.warrantyExpiredAt)}'),
            return ListView(padding: const EdgeInsets.all(16), children: [
            }
                  'Garansi sudah berakhir pada ${shortDate(data.warrantyExpiredAt)}.');
              return EmptyMessage(
                DateTime.now().isAfter(data.warrantyExpiredAt!)) {
            if (data.warrantyExpiredAt == null ||
          builder: (data) {
          value: order,
      child: AsyncPage(
      title: 'Klaim Garansi',
    return CustomerScaffold(
    final order = ref.watch(orderDetailProvider(widget.orderId));
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      }
        context.pop();
                'Klaim diterima. Admin toko akan merespons dalam 24 jam.')));
            content: Text(
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      if (mounted) {
      ref.invalidate(orderDetailProvider(widget.orderId));
          evidenceUrls: urls);
          description: _description.text,
          disputeType: _type,
          orderId: widget.orderId,
      await ref.read(disputeRepositoryProvider).createDispute(
      }
            .uploadFile(file, 'evidence', null));
            .read(uploadRepositoryProvider)
        urls.add(await ref
      for (final file in _files) {
      final urls = <String>[];
    try {
    setState(() => _loading = true);
    }
      return;
          const SnackBar(content: Text('Deskripsi minimal 20 karakter.')));
      ScaffoldMessenger.of(context).showSnackBar(
    if (_description.text.length < 20) {
  Future<void> _submit() async {

  bool _loading = false;
  final _files = <XFile>[];
  String _type = 'warranty_claim';
  final _description = TextEditingController();
class _WarrantyClaimScreenState extends ConsumerState<WarrantyClaimScreen> {

}
      _WarrantyClaimScreenState();
  ConsumerState<WarrantyClaimScreen> createState() =>
  @override
  final String orderId;
  const WarrantyClaimScreen({super.key, required this.orderId});
class WarrantyClaimScreen extends ConsumerStatefulWidget {

}
      );
        ]),
              child: const Text('Kembali ke Pesanan')),
              onPressed: () => context.go('/orders'),
          OutlinedButton(
              child: const Text('Lihat Kupon Saya')),
              onPressed: () => context.go('/coupons'),
          FilledButton(
          if (result.coupon != null) CouponRewardBanner(coupon: result.coupon!),
                  ?.copyWith(fontWeight: FontWeight.w800)),
                  .headlineSmall
                  .textTheme
              style: Theme.of(context)
              textAlign: TextAlign.center,
          Text('Ulasan berhasil dikirim!',
          const Icon(Icons.celebration, size: 80, color: Colors.orange),
        child: ListView(padding: const EdgeInsets.all(24), children: [
        title: 'Ulasan Berhasil',
  Widget build(BuildContext context) => CustomerScaffold(
  @override
  final ReviewResult result;
  const ReviewSuccessScreen({super.key, required this.result});
class ReviewSuccessScreen extends StatelessWidget {

}
      );
        ]),
              child: Text(_loading ? 'Mengirim...' : 'Kirim Ulasan')),
              onPressed: _loading ? null : _submit,
          FilledButton(
                  labelText: 'Komentar', border: OutlineInputBorder())),
              decoration: const InputDecoration(
              maxLines: 6,
              minLines: 4,
              maxLength: 500,
              controller: _comment,
          TextField(
          const SizedBox(height: 16),
              textAlign: TextAlign.center),
              ][_rating],
                'Sangat Bagus'
                'Bagus',
                'Biasa',
                'Buruk',
                'Sangat Buruk',
                '',
              [
          Text(
                          color: Colors.amber)))),
                          index < _rating ? Icons.star : Icons.star_border,
                      icon: Icon(
                      onPressed: () => setState(() => _rating = index + 1),
                      iconSize: 38,
                  (index) => IconButton(
                  5,
              children: List.generate(
              mainAxisAlignment: MainAxisAlignment.center,
          Row(
        child: ListView(padding: const EdgeInsets.all(16), children: [
        title: 'Beri Ulasan',
  Widget build(BuildContext context) => CustomerScaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      if (mounted) context.go('/review-success', extra: result);
      ref.invalidate(orderDetailProvider(widget.orderId));
          orderId: widget.orderId, rating: _rating, comment: _comment.text);
      final result = await ref.read(reviewRepositoryProvider).createReview(
    try {
    setState(() => _loading = true);
  Future<void> _submit() async {
  bool _loading = false;
  int _rating = 5;
  final _comment = TextEditingController();
class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {

}
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
  @override
  final String orderId;
  const ReviewFormScreen({super.key, required this.orderId});
class ReviewFormScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        },
          ]);
                child: Text(_loading ? 'Mengirim...' : 'Kirim Pembayaran')),
                onPressed: _loading ? null : () => _submit(order),
            FilledButton(
            const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
            if (_progress > 0 && _progress < 1)
            if (_file != null) Text('Dipilih: ${_file!.name}'),
                label: Text(_file?.name ?? 'Ambil dari Galeri')),
                icon: const Icon(Icons.image),
                },
                  if (picked != null) setState(() => _file = picked);
                      maxWidth: 1600);
                      imageQuality: 72,
                      source: ImageSource.gallery,
                  final picked = await ImagePicker().pickImage(
                onPressed: () async {
            OutlinedButton.icon(
                label: const Text('Hapus Foto')),
                icon: const Icon(Icons.delete_outline),
                onPressed: () async => setState(() => _file = null),
            OutlinedButton.icon(
            const SizedBox(height: 12),
                decoration: const InputDecoration(labelText: 'Nominal')),
                keyboardType: TextInputType.number,
                controller: _amount,
            TextField(
                onChanged: (v) => setState(() => _type = v!)),
                ],
                      value: 'final_payment', child: Text('Pelunasan Final')),
                  DropdownMenuItem(
                  DropdownMenuItem(value: 'deposit', child: Text('Uang Muka')),
                items: const [
                    const InputDecoration(labelText: 'Jenis Pembayaran'),
                decoration:
                initialValue: _type,
            DropdownButtonFormField(
                onChanged: (v) => setState(() => _method = v!)),
                ],
                  DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                      value: 'transfer_bank', child: Text('Transfer Bank')),
                  DropdownMenuItem(
                items: const [
                    const InputDecoration(labelText: 'Metode Pembayaran'),
                decoration:
                initialValue: _method,
            DropdownButtonFormField(
            }),
              'Sisa': rupiah(due)
              'Sudah Bayar': rupiah(confirmed),
              'Final': rupiah(order.finalPrice ?? order.totalEstimasi),
              'Order': order.orderNumber,
            _InfoCard(title: 'Tagihan', rows: {
          return ListView(padding: const EdgeInsets.all(16), children: [
            _amount.text = due.clamp(0, double.infinity).toStringAsFixed(0);
          if (_amount.text.isEmpty)
          final due = (order.finalPrice ?? order.totalEstimasi) - confirmed;
              .fold<double>(0, (sum, p) => sum + p.amount);
              .where((p) => p.status == 'confirmed')
          final confirmed = order.payments
        builder: (order) {
        value: orderValue,
      child: AsyncPage(
      title: 'Pembayaran',
    return CustomerScaffold(
    final orderValue = ref.watch(orderDetailProvider(widget.orderId));
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      }
        context.pop();
            content: Text('Pembayaran dikirim, menunggu konfirmasi toko.')));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      if (mounted) {
      ref.invalidate(orderDetailProvider(order.id));
          proofUrl: proofUrl);
          type: _type,
          method: _method,
          amount: amount,
          orderId: order.id,
      await ref.read(paymentRepositoryProvider).createPayment(
              _file!, 'payments', (p) => setState(() => _progress = p));
          : await ref.read(uploadRepositoryProvider).uploadFile(
          ? null
      final proofUrl = _file == null
    try {
    setState(() => _loading = true);
    }
      return;
          const SnackBar(content: Text('Bukti transfer wajib diunggah.')));
      ScaffoldMessenger.of(context).showSnackBar(
    if (_method == 'transfer_bank' && _file == null) {
    if (amount <= 0) return;
        double.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final amount =
  Future<void> _submit(CustomerOrder order) async {

  bool _loading = false;
  double _progress = 0;
  XFile? _file;
  String _type = 'final_payment';
  String _method = 'transfer_bank';
  final _amount = TextEditingController();
class _PaymentUploadScreenState extends ConsumerState<PaymentUploadScreen> {

}
      _PaymentUploadScreenState();
  ConsumerState<PaymentUploadScreen> createState() =>
  @override
  final String orderId;
  const PaymentUploadScreen({super.key, required this.orderId});
class PaymentUploadScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        error: (error, _) => Center(child: Text(parseApiError(error))),
        loading: () => const SkeletonList(),
        ]),
              textAlign: TextAlign.center),
              'Diperbarui: ${DateFormat('HH:mm', 'id_ID').format(DateTime.now())}',
          Text(
          const SizedBox(height: 12),
          OrderStatusTimeline(entries: order.tracking),
        data: (order) => ListView(padding: const EdgeInsets.all(16), children: [
      child: tracking.when(
      title: 'Tracking',
    return CustomerScaffold(
    final tracking = ref.watch(orderTrackingProvider(orderId));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
class TrackingScreen extends ConsumerWidget {

}
      ]);
              label: const Text('Klaim Garansi')),
              icon: const Icon(Icons.shield),
                  context.push('/orders/${order.id}/warranty-claim'),
              onPressed: () =>
          OutlinedButton.icon(
            DateTime.now().isBefore(order.warrantyExpiredAt!))
            order.warrantyExpiredAt != null &&
        if (order.status == OrderStatus.completed &&
              label: const Text('Beri Ulasan')),
              icon: const Icon(Icons.star),
              onPressed: () => context.push('/orders/${order.id}/review'),
          FilledButton.icon(
        if (order.status == OrderStatus.completed && !order.reviewed)
              label: const Text('Upload Bukti Bayar')),
              icon: const Icon(Icons.payment),
              onPressed: () => context.push('/orders/${order.id}/payment'),
          FilledButton.icon(
        if (order.status == OrderStatus.waitingPayment)
  Widget build(BuildContext context) => Column(children: [
  @override
  final CustomerOrder order;
  const _OrderActions({required this.order});
class _OrderActions extends StatelessWidget {

}
      );
        ),
          ]),
            ]),
                      child: const Text('Tolak'))),
                      onPressed: _loading ? null : () => _approve(false),
                  child: OutlinedButton(
              Expanded(
              const SizedBox(width: 8),
                      child: const Text('Setuju'))),
                      onPressed: _loading ? null : () => _approve(true),
                  child: FilledButton(
              Expanded(
            Row(children: [
            const SizedBox(height: 12),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('Total: ${rupiah(widget.order.finalPrice ?? 0)}',
            const Divider(),
              Text('Service Fee: ${rupiah(widget.order.serviceFee!)}'),
            if (widget.order.serviceFee != null)
                '${item.serviceType}: ${rupiah(item.finalItemPrice ?? item.itemPrice)}')),
            ...widget.order.items.map((item) => Text(
            const SizedBox(height: 8),
              Text(widget.order.diagnosisNote!),
            if (widget.order.diagnosisNote != null)
                style: TextStyle(fontWeight: FontWeight.w900)),
            const Text('Hasil Diagnosa',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          child:
          padding: const EdgeInsets.all(16),
        child: Padding(
        color: Theme.of(context).colorScheme.primaryContainer,
  Widget build(BuildContext context) => Card(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      ref.invalidate(orderDetailProvider(widget.order.id));
      }
        await ref.read(orderRepositoryProvider).rejectOrder(widget.order.id);
      } else {
        await ref.read(orderRepositoryProvider).approveOrder(widget.order.id);
      if (approve) {
    try {
    setState(() => _loading = true);
  Future<void> _approve(bool approve) async {
  bool _loading = false;
class _DiagnosisApprovalCardState extends ConsumerState<DiagnosisApprovalCard> {

}
      _DiagnosisApprovalCardState();
  ConsumerState<DiagnosisApprovalCard> createState() =>
  @override
  final CustomerOrder order;
  const DiagnosisApprovalCard({super.key, required this.order});
class DiagnosisApprovalCard extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ]),
            _OrderActions(order: order),
                  subtitle: Text('${p.paymentMethod} - ${p.status}'))),
                  title: Text(rupiah(p.amount)),
              ...order.payments.map((p) => ListTile(
            else
              const Text('Belum ada pembayaran.')
            if (order.payments.isEmpty)
            const SectionTitle('Pembayaran'),
                child: const Text('Lihat Semua Tracking')),
                onPressed: () => context.push('/orders/$orderId/tracking'),
            TextButton(
            OrderStatusTimeline(entries: order.tracking.take(3).toList()),
            const SectionTitle('Tracking', action: null),
              DiagnosisApprovalCard(order: order),
            if (order.status == OrderStatus.waitingApproval)
                          'Batas waktu: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.slaDeadline!)}'))),
                      child: Text(
                      padding: const EdgeInsets.all(16),
                  child: Padding(
              Card(
            if (order.slaDeadline != null)
                trailing: Text(rupiah(item.finalItemPrice ?? item.itemPrice)))),
                subtitle: Text(item.complaint),
                title: Text(item.serviceType),
            ...order.items.map((item) => ListTile(
            const SectionTitle('Item Order'),
            }),
              if (order.finalPrice != null) 'Final': rupiah(order.finalPrice!)
                'Diskon': '-${rupiah(order.discountAmount)}',
              if (order.discountAmount > 0)
              'Estimasi': rupiah(order.totalEstimasi),
            _InfoCard(title: 'Harga', rows: {
            }),
              'Telepon': order.storePhone ?? '-'
              'Alamat': order.storeAddress ?? '-',
              'Nama': order.storeName ?? '-',
            _InfoCard(title: 'Toko', rows: {
            }),
                'Alamat': order.deliveryAddress!
              if (order.deliveryAddress != null)
              'Pengiriman': order.deliveryMethod,
              'Jenis': order.deviceType,
              'Model': order.deviceModel,
              'Brand': order.brand,
            _InfoCard(title: 'Perangkat', rows: {
            const SizedBox(height: 16),
            ]),
              StatusPill(order.status)
                          ?.copyWith(fontWeight: FontWeight.w800))),
                          .titleLarge
                          .textTheme
                      style: Theme.of(context)
                  child: SelectableText(order.orderNumber,
              Expanded(
            Row(children: [
          child: ListView(padding: const EdgeInsets.all(16), children: [
          onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
        builder: (order) => RefreshIndicator(
        value: orderValue,
      child: AsyncPage(
      title: 'Detail Pesanan',
    return CustomerScaffold(
    final orderValue = ref.watch(orderDetailProvider(orderId));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
class OrderDetailScreen extends ConsumerWidget {

}
  }
    );
                      .toList())),
                          onTap: () => context.push('/orders/${order.id}')))
                          order: order,
                      .map((order) => OrderCard(
                  children: items
              : ListView(
              ? const EmptyMessage('Tidak ada pesanan.')
          builder: (items) => items.isEmpty
          value: orders,
      child: AsyncPage(
      onRefresh: () async => ref.invalidate(customerOrdersProvider(group)),
    return RefreshIndicator(
    final orders = ref.watch(customerOrdersProvider(group));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String group;
  const _OrderTab(this.group);
class _OrderTab extends ConsumerWidget {

}
      );
        ),
          ]),
            ])),
              _OrderTab('cancelled')
              _OrderTab('completed'),
              _OrderTab('active'),
                child: TabBarView(children: [
            Expanded(
            ]),
              Tab(text: 'Dibatalkan')
              Tab(text: 'Selesai'),
              Tab(text: 'Aktif'),
            TabBar(tabs: [
          child: Column(children: [
          length: 3,
        child: DefaultTabController(
        title: 'Pesanan Saya',
  Widget build(BuildContext context) => const CustomerScaffold(
  @override
class _OrderListScreenState extends ConsumerState<OrderListScreen> {

}
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
  @override
  const OrderListScreen({super.key});
class OrderListScreen extends ConsumerStatefulWidget {

}
      );
        ]),
              child: const Text('Kembali ke Beranda')),
              onPressed: () => context.go('/home'),
          OutlinedButton(
              child: const Text('Lihat Pesanan Saya')),
              onPressed: () => context.go('/orders'),
          FilledButton(
          const SizedBox(height: 24),
                            'Cek WhatsApp kamu. Admin toko akan mengirimkan informasi akun ServisGadget.')))),
                        child: Text(
                        padding: EdgeInsets.all(16),
                    child: Padding(
                child: Card(
                padding: EdgeInsets.only(top: 16),
            const Padding(
          if (isNewCustomer)
              textAlign: TextAlign.center),
          const Text('Admin toko akan segera mengkonfirmasi perangkatmu.',
          const SizedBox(height: 16),
          SelectableText(orderNumber, textAlign: TextAlign.center),
          const SizedBox(height: 8),
                  ?.copyWith(fontWeight: FontWeight.w800)),
                  .headlineSmall
                  .textTheme
              style: Theme.of(context)
              textAlign: TextAlign.center,
          Text('Order berhasil dibuat!',
          const SizedBox(height: 16),
          const Icon(Icons.check_circle, size: 84, color: Colors.green),
        child: ListView(padding: const EdgeInsets.all(24), children: [
        title: 'Order Berhasil',
  Widget build(BuildContext context) => CustomerScaffold(
  @override
  final bool isNewCustomer;
  final String orderNumber;
      {super.key, required this.orderNumber, required this.isNewCustomer});
  const BookingSuccessScreen(
class BookingSuccessScreen extends StatelessWidget {

}
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
  String? _required(String? value) =>

  }
    );
      ),
            ]),
                      border: OutlineInputBorder())),
                      labelText: 'Kode Kupon (opsional)',
                  decoration: const InputDecoration(
                  controller: _coupon,
              TextFormField(
              const SizedBox(height: 12),
              ],
                    validator: _required),
                        border: OutlineInputBorder()),
                        labelText: 'Alamat Pickup',
                    decoration: const InputDecoration(
                    controller: _address,
                TextFormField(
                const SizedBox(height: 12),
              if (_delivery == 'courier_pickup') ...[
                      setState(() => _delivery = v.first)),
                  onSelectionChanged: (v) =>
                  ],
                        value: 'courier_pickup', label: Text('Pickup Kurir'))
                    ButtonSegment(
                        value: 'walk_in', label: Text('Antar Sendiri')),
                    ButtonSegment(
                  segments: const [
                  },
                    _delivery
                  selected: {
              SegmentedButton(
              const SectionTitle('Pengiriman'),
                  label: Text(_selectedPart?.partName ?? 'Pilih Sparepart')),
                  icon: const Icon(Icons.inventory),
                      spareparts.isEmpty ? null : () => _selectPart(spareparts),
                  onPressed:
              OutlinedButton.icon(
              const SizedBox(height: 12),
                      : null),
                      ? 'Minimal 10 karakter.'
                  validator: (v) => v == null || v.length < 10
                      border: OutlineInputBorder()),
                      labelText: 'Deskripsi kerusakan',
                  decoration: const InputDecoration(
                  maxLines: 5,
                  minLines: 3,
                  controller: _complaint,
              TextFormField(
              const SizedBox(height: 12),
                  onChanged: (v) => setState(() => _serviceType = v!)),
                  ],
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                    DropdownMenuItem(value: 'camera', child: Text('Kamera')),
                        value: 'charging_port', child: Text('Port')),
                    DropdownMenuItem(
                        value: 'battery_replacement', child: Text('Baterai')),
                    DropdownMenuItem(
                        value: 'screen_replacement', child: Text('Layar')),
                    DropdownMenuItem(
                  items: const [
                      labelText: 'Jenis Servis', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  value: _serviceType,
              DropdownButtonFormField(
              const SectionTitle('Kerusakan'),
                  validator: _required),
                      labelText: 'Model Device', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  controller: _model,
              TextFormField(
              const SizedBox(height: 12),
                  validator: _required),
                      labelText: 'Brand', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  controller: _brand,
              TextFormField(
              const SizedBox(height: 12),
                      setState(() => _deviceType = v.first)),
                  onSelectionChanged: (v) =>
                  ],
                    ButtonSegment(value: 'ios', label: Text('iOS'))
                    ButtonSegment(value: 'android', label: Text('Android')),
                  segments: const [
                  },
                    _deviceType
                  selected: {
              SegmentedButton(
              const SectionTitle('Info Perangkat'),
                  validator: _required),
                      labelText: 'Nomor HP', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  keyboardType: TextInputType.phone,
                  controller: _phone,
              TextFormField(
              const SizedBox(height: 12),
                  validator: _required),
                      labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  controller: _name,
              TextFormField(
              const SectionTitle('Info Pelanggan'),
            children: [
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: ListView(
        key: _form,
      child: Form(
      ),
                : 'Estimasi ${rupiah(_estimate)} - Buat Order')),
                ? 'Membuat order...'
            label: Text(_loading
            icon: const Icon(Icons.check),
            onPressed: _loading ? null : _submit,
        child: FilledButton.icon(
        margin: const EdgeInsets.only(left: 32),
        width: double.infinity,
      floatingActionButton: Container(
      title: 'Buat Order',
    return CustomerScaffold(
            const <SparePart>[];
        ref.watch(sparepartsProvider(widget.storeId)).valueOrNull ??
    final spareparts =
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
          extra: result.isNewCustomer);
      context.go('/booking-success/${result.orderNumber}',
      if (!mounted) return;
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      );
        ],
              price: _estimate)
              sparepartId: _selectedPart?.id,
              complaint: _complaint.text,
              serviceType: _serviceType,
          CreateOrderItemInput(
        items: [
        couponCode: _coupon.text,
        deliveryAddress: _delivery == 'courier_pickup' ? _address.text : null,
        deliveryMethod: _delivery,
        deviceModel: _model.text,
        brand: _brand.text,
        deviceType: _deviceType,
        phoneNumber: normalizePhone(_phone.text),
        fullName: _name.text,
        storeId: widget.storeId,
      final req = CreateOrderRequest(
    try {
    setState(() => _loading = true);
    if (!_form.currentState!.validate()) return;
  Future<void> _submit() async {

  }
    if (part != null) setState(() => _selectedPart = part);
    );
      ),
            .toList(),
                ))
                      : () => Navigator.pop(context, part),
                      ? null
                  onTap: part.availableQty <= 0
                  trailing: Text(rupiah(part.price)),
                  subtitle: Text('${part.availableQty} tersedia'),
                  title: Text(part.partName),
                  enabled: part.availableQty > 0,
            .map((part) => ListTile(
        children: parts
        padding: const EdgeInsets.all(16),
      builder: (context) => ListView(
      context: context,
    final part = await showModalBottomSheet<SparePart>(
  Future<void> _selectPart(List<SparePart> parts) async {

  }
    }
      _address.text = user.address ?? '';
      _phone.text = user.phoneNumber;
      _name.text = user.fullName;
    if (user != null) {
    final user = ref.read(customerAuthProvider).valueOrNull;
    super.initState();
  void initState() {
  @override

  double get _estimate => _selectedPart?.price ?? 0;

  bool _loading = false;
  SparePart? _selectedPart;
  String _serviceType = 'screen_replacement';
  String _delivery = 'walk_in';
  String _deviceType = 'android';
  final _address = TextEditingController();
  final _coupon = TextEditingController();
  final _complaint = TextEditingController();
  final _model = TextEditingController();
  final _brand = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {

}
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
  @override
  final String storeId;
  const BookingFormScreen({super.key, required this.storeId});
class BookingFormScreen extends ConsumerStatefulWidget {

}
  );
    ),
      ]),
          )),
            label: Text(_loading ? 'Membuat...' : 'Buat Booking'),
            icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            onPressed: _loading ? null : _createBooking,
          Expanded(child: FilledButton.icon(
        if (_step == 4)
          )),
            label: Text(_step == 1 ? 'Cari Toko' : 'Lanjut'),
            icon: const Icon(Icons.arrow_forward),
            onPressed: _loading ? null : _nextStep,
          Expanded(child: FilledButton.icon(
        if (_step < 4)
        if (_step > 0) const SizedBox(width: 12),
          )),
            label: const Text('Kembali'),
            icon: const Icon(Icons.arrow_back),
            onPressed: _loading ? null : _prevStep,
          Expanded(child: OutlinedButton.icon(
        if (_step > 0)
      child: Row(children: [
      padding: const EdgeInsets.all(16),
    child: Padding(
  Widget _buildBottomNav(ThemeData theme) => SafeArea(

  );
    ]),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    padding: const EdgeInsets.symmetric(vertical: 6),
  Widget _confirmRow(ThemeData theme, String label, String value) => Padding(

  );
    ],
      ),
        decoration: const InputDecoration(labelText: 'Kode Kupon (opsional)', prefixIcon: Icon(Icons.local_offer_outlined), isDense: true),
        controller: _coupon,
      TextField(
      const SizedBox(height: 16),
      ),
        ),
          ]),
            Text('* Estimasi bersifat sementara, dapat berubah setelah diagnosis teknisi.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            ]),
              Text(rupiah(_estimateCost), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const Spacer(),
              Text('Estimasi Biaya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Row(children: [
            const Divider(height: 24),
            _confirmRow(theme, 'Pengiriman', _delivery == 'walk_in' ? 'Antar ke Toko' : 'Pickup Kurir'),
            const Divider(),
            ],
              _confirmRow(theme, 'Alamat', _address.text),
              const Divider(),
            if (_delivery == 'courier_pickup') ...[
            _confirmRow(theme, 'WhatsApp', _phone.text),
            const Divider(),
            _confirmRow(theme, 'Nama', _name.text),
            const Divider(),
            _confirmRow(theme, 'Keluhan', _complaint.text),
            const Divider(),
            _confirmRow(theme, 'Layanan', _serviceTypeLabels[_serviceType]!),
            const Divider(),
            _confirmRow(theme, 'Perangkat', '${_deviceType.toUpperCase()} - ${_selectedBrand ?? '-'} ${_selectedModel ?? '-'}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          padding: const EdgeInsets.all(16),
        child: Padding(
      Card(
      const SizedBox(height: 16),
      Text('Konfirmasi Booking', style: theme.textTheme.titleLarge),
    children: [
    padding: const EdgeInsets.all(16),
  Widget _buildStep5(ThemeData theme) => ListView(

  );
    ],
      ],
        ),
          decoration: const InputDecoration(labelText: 'Alamat Penjemputan', prefixIcon: Icon(Icons.location_on_outlined), alignLabelWithHint: true),
          controller: _address, maxLines: 2, textCapitalization: TextCapitalization.sentences,
        TextField(
        const SizedBox(height: 16),
      if (_delivery == 'courier_pickup') ...[
      ),
        decoration: const InputDecoration(labelText: 'Nomor WhatsApp', prefixText: '08', prefixIcon: Icon(Icons.phone_outlined)),
        controller: _phone, keyboardType: TextInputType.phone,
      TextField(
      const SizedBox(height: 16),
      ),
        decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
        controller: _name, textCapitalization: TextCapitalization.words,
      TextField(
      const SizedBox(height: 24),
      ),
        showSelectedIcon: false,
        onSelectionChanged: (v) => setState(() => _delivery = v.first),
        selected: {_delivery},
        ],
          ButtonSegment(value: 'courier_pickup', label: Text('Pickup Kurir'), icon: Icon(Icons.local_shipping)),
          ButtonSegment(value: 'walk_in', label: Text('Antar ke Toko'), icon: Icon(Icons.store)),
        segments: const [
      SegmentedButton<String>(
      const SizedBox(height: 24),
      Text('Data Diri & Pengiriman', style: theme.textTheme.titleLarge),
    children: [
    padding: const EdgeInsets.all(16),
  Widget _buildStep4(ThemeData theme) => ListView(

  }
    );
      ],
        }),
          );
            ),
              ),
                ]),
                  ]),
                    Text('Estimasi awal: ${rupiah(store.estimatedCost)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.info_outline, size: 16),
                  Row(children: [
                  const Divider(height: 16),
                  )),
                    ]),
                      Text(rupiah(sp.price), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      ),
                        child: Text(sp.status == 'available' ? 'Tersedia' : 'Preorder', style: TextStyle(fontSize: 11, color: sp.status == 'available' ? Colors.green : Colors.orange)),
                        ),
                          borderRadius: BorderRadius.circular(4),
                          color: sp.status == 'available' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        decoration: BoxDecoration(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      Container(
                      Expanded(child: Text(sp.partName, style: theme.textTheme.bodyMedium)),
                      const SizedBox(width: 8),
                      const Icon(Icons.build, size: 14),
                    child: Row(children: [
                    padding: const EdgeInsets.only(top: 4),
                  ...store.spareparts.map((sp) => Padding(
                  const SizedBox(height: 8),
                  ),
                    child: Text('${store.totalCompleted} servis selesai', style: theme.textTheme.labelSmall),
                    ),
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.tertiaryContainer,
                    decoration: BoxDecoration(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  Container(
                  const SizedBox(height: 8),
                  ]),
                    Expanded(child: Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  Row(children: [
                  const SizedBox(height: 4),
                  ]),
                    ]),
                      Text(store.ratingAvg.toStringAsFixed(1), style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                    Row(children: [
                    Expanded(child: Text(store.storeName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                  Row(children: [
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                padding: const EdgeInsets.all(16),
              child: Padding(
              onTap: () => _selectStore(store),
              borderRadius: BorderRadius.circular(12),
            child: InkWell(
            ),
              side: selected ? BorderSide(color: theme.colorScheme.primary) : BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            shape: RoundedRectangleBorder(
            color: selected ? theme.colorScheme.primaryContainer : null,
            margin: const EdgeInsets.only(bottom: 12),
          return Card(
          final selected = store.storeId == _selectedStoreId;
        ..._matchedStores.map((store) {
        const SizedBox(height: 16),
        Text('${_matchedStores.length} toko tersedia untuk perangkat kamu.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Pilih Toko Mitra', style: theme.textTheme.titleLarge),
      children: [
      padding: const EdgeInsets.all(16),
    return ListView(
    }
      );
        ],
          ),
            label: const Text('Kembali'),
            icon: const Icon(Icons.arrow_back),
            onPressed: _prevStep,
          FilledButton.icon(
          const SizedBox(height: 24),
          Text('Silakan periksa kembali brand, tipe, atau jenis layanan yang dipilih.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Text('Tidak ada toko yang cocok untuk perangkat ${_selectedBrand ?? '-'} ${_selectedModel ?? '-'} dengan layanan ini.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 24),
          Text('Rekomendasi Toko Mitra', style: theme.textTheme.titleLarge),
        children: [
        padding: const EdgeInsets.all(16),
      return ListView(
    if (_matchedStores.isEmpty) {
    }
      return const Center(child: CircularProgressIndicator());
    if (_loading && _matchedStores.isEmpty) {
  Widget _buildStep3(ThemeData theme) {

  );
    ],
      ),
        ),
          alignLabelWithHint: true,
          prefixIcon: Padding(padding: EdgeInsets.only(bottom: 64), child: Icon(Icons.report_problem_outlined)),
          hintText: 'Jelaskan kerusakan yang dialami, contoh:\n- Layar retak dari pojok kiri bawah\n- Baterai cepat habis (health < 70%)\n- Bootloop, tidak bisa masuk home screen',
          labelText: 'Keluhan / Deskripsi Kerusakan',
        decoration: const InputDecoration(
        controller: _complaint, maxLines: 4, textCapitalization: TextCapitalization.sentences,
      TextField(
      const SizedBox(height: 24),
      ),
        )).toList(),
          onSelected: (v) { if (v) setState(() => _serviceType = e.key); },
          selected: _serviceType == e.key,
          label: Text(e.value),
        children: _serviceTypeLabels.entries.map((e) => ChoiceChip(
        spacing: 8, runSpacing: 8,
      Wrap(
      const SizedBox(height: 24),
      Text('Pilih jenis layanan yang dibutuhkan dan jelaskan keluhannya.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      Text('Jenis Kerusakan / Layanan', style: theme.textTheme.titleLarge),
    children: [
    padding: const EdgeInsets.all(16),
  Widget _buildStep2(ThemeData theme) => ListView(

  }
    );
      ],
        ),
          },
            ]);
              ),
                onChanged: _selectedBrand == null ? null : (value) => setState(() => _selectedModel = value),
                items: models.map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                decoration: const InputDecoration(labelText: 'Tipe Smartphone', prefixIcon: Icon(Icons.smartphone)),
                value: modelValue,
              DropdownButtonFormField<String>(
              const SizedBox(height: 16),
              ),
                }),
                  _selectedModel = null;
                  _selectedBrand = value;
                onChanged: (value) => setState(() {
                items: brands.map((brand) => DropdownMenuItem(value: brand, child: Text(brand))).toList(),
                decoration: const InputDecoration(labelText: 'Brand Smartphone', prefixIcon: Icon(Icons.branding_watermark)),
                value: brandValue,
              DropdownButtonFormField<String>(
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            final modelValue = models.contains(_selectedModel) ? _selectedModel : null;
            final brandValue = brands.contains(_selectedBrand) ? _selectedBrand : null;
                : (selectedGroups.first.models.toSet().toList()..sort());
                ? const <String>[]
            final models = selectedGroups.isEmpty
            final selectedGroups = groups.where((group) => group.brand == _selectedBrand).toList();
            final brands = groups.map((group) => group.brand).toSet().toList()..sort();

            }
              return const EmptyMessage('Belum ada sparepart tersedia');
            if (groups.isEmpty) {
          data: (groups) {
          error: (error, _) => Text('Gagal memuat daftar perangkat: $error', style: TextStyle(color: theme.colorScheme.error)),
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
        deviceModels.when(
        const SizedBox(height: 24),
        ),
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _deviceType = v.first),
          selected: {_deviceType},
          ],
            ButtonSegment(value: 'ios', label: Text('iPhone / iOS'), icon: Icon(Icons.phone_iphone)),
            ButtonSegment(value: 'android', label: Text('Android'), icon: Icon(Icons.android)),
          segments: const [
        SegmentedButton<String>(
        const SizedBox(height: 24),
        Text('Pilih jenis smartphone lalu pilih brand dan tipe yang tersedia dari data sparepart toko.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Pilih Jenis & Tipe Perangkat', style: theme.textTheme.titleLarge),
      children: [
      padding: const EdgeInsets.all(16),
    return ListView(

    final deviceModels = ref.watch(deviceModelsProvider);
  Widget _buildStep1(ThemeData theme) {

  }
    );
      ),
        ),
          ],
            _buildBottomNav(theme),
            ),
              ),
                ],
                  _buildStep5(theme),
                  _buildStep4(theme),
                  _buildStep3(theme),
                  _buildStep2(theme),
                  _buildStep1(theme),
                children: [
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
              child: PageView(
            Expanded(
            const Divider(),
            ),
              ),
                }),
                  );
                    ]),
                      Text(steps[i], style: TextStyle(fontSize: 10, color: active || done ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      ),
                        ),
                            : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : theme.colorScheme.onSurfaceVariant)),
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                          child: done
                        child: Center(
                        ),
                          color: done ? theme.colorScheme.primary : active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        decoration: BoxDecoration(
                        width: 28, height: 28,
                      Container(
                    child: Column(children: [
                  return Expanded(
                  final done = i < _step;
                  final active = i == _step;
                children: List.generate(steps.length, (i) {
              child: Row(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            Padding(
          children: [
        child: Column(
      body: SafeArea(
      ),
        ),
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back),
        leading: IconButton(
        title: const Text('Service Now'),
      appBar: AppBar(
    return Scaffold(

    final steps = ['Perangkat', 'Kerusakan', 'Toko', 'Data Diri', 'Konfirmasi'];
    final theme = Theme.of(context);
  Widget build(BuildContext context) {
  @override

  }
    setState(() => _step -= 1);
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _pageController.previousPage(
    if (_step <= 0) return;
  void _prevStep() {

  }
    setState(() => _step += 1);
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _pageController.nextPage(

    }
      return;
      });
        }
          setState(() => _step = 2);
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          _pageController.nextPage(
        if (mounted) {
      _matchStores().then((_) {
    if (_step == 1) {

    if (_step == 3 && (_name.text.isEmpty || _phone.text.isEmpty)) return;
    if (_step == 2 && _selectedStoreId == null) return;
    if (_step == 1 && _complaint.text.isEmpty) return;
    if (_step == 0 && (_selectedBrand == null || _selectedModel == null)) return;
    if (_step >= 4) return;
  void _nextStep() {

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
      }
        );
          SnackBar(content: Text(parseApiError(error))),
        ScaffoldMessenger.of(context).showSnackBar(
      if (mounted) {
    } catch (error) {
      context.go('/booking-success/${result.orderNumber}', extra: result.isNewCustomer);
      if (!mounted) return;
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      );
        ],
          ),
            price: _estimateCost,
            sparepartId: _selectedPartId,
            complaint: _complaint.text.trim(),
            serviceType: _serviceType,
          CreateOrderItemInput(
        items: [
        couponCode: _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
        deliveryAddress: _delivery == 'courier_pickup' ? _address.text.trim() : null,
        deliveryMethod: _delivery,
        deviceModel: _selectedModel!,
        brand: _selectedBrand!,
        deviceType: _deviceType,
        phoneNumber: normalizePhone(_phone.text.trim()),
        fullName: _name.text.trim(),
        storeId: _selectedStoreId!,
      final req = CreateOrderRequest(
    try {
    setState(() => _loading = true);
  Future<void> _createBooking() async {

  }
    });
      _estimateCost = store.estimatedCost;
      _selectedStoreId = store.storeId;
    setState(() {
  void _selectStore(StoreMatchResult store) {

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
      _matchedStores = const [];
    } catch (_) {
      );
        partType: _serviceType,
        deviceModel: _selectedModel!,
        brand: _selectedBrand!,
      _matchedStores = await repo.matchStores(
      final repo = ref.read(storeDiscoveryRepositoryProvider);
    try {
    setState(() => _loading = true);
    if (_selectedBrand == null || _selectedModel == null) return;
  Future<void> _matchStores() async {

  }
    super.dispose();
    _coupon.dispose();
    _address.dispose();
    _phone.dispose();
    _name.dispose();
    _complaint.dispose();
    _pageController.dispose();
  void dispose() {
  @override

  }
    }
      _address.text = user.address ?? '';
      _phone.text = user.phoneNumber;
      _name.text = user.fullName;
    if (user != null) {
    final user = ref.read(customerAuthProvider).valueOrNull;
    super.initState();
  void initState() {
  @override

  };
    'other': 'Lainnya',
    'camera': 'Kamera',
    'charging_port': 'Port Charger',
    'battery_replacement': 'Ganti Baterai',
    'screen_replacement': 'Ganti Layar',
  final _serviceTypeLabels = const {

  List<StoreMatchResult> _matchedStores = const [];
  bool _loading = false;
  double _estimateCost = 0;
  String? _selectedPartId;
  String? _selectedStoreId;
  String _delivery = 'walk_in';
  String _serviceType = 'screen_replacement';
  String _deviceType = 'android';
  final _coupon = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _complaint = TextEditingController();
  String? _selectedModel;
  String? _selectedBrand;
  int _step = 0;
  final _pageController = PageController();
class _ServiceFlowScreenState extends ConsumerState<ServiceFlowScreen> {

}
  ConsumerState<ServiceFlowScreen> createState() => _ServiceFlowScreenState();
  @override
  const ServiceFlowScreen({super.key});
class ServiceFlowScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ]),
            ),
              ]),
                            .toList()),
                                    Text(review.comment ?? 'Tanpa komentar')))
                                subtitle:
                                title: Text('${review.rating}/5'),
                            .map((review) => ListTile(
                        children: store.reviews
                    : ListView(
                    ? const EmptyMessage('Belum ada ulasan.')
                store.reviews.isEmpty
                ),
                      const EmptyMessage('Sparepart gagal dimuat.'),
                  error: (_, __) =>
                  loading: () => const SkeletonList(),
                              .toList()),
                                      : rupiah(part.price))))
                                      ? 'Habis'
                                  trailing: Text(part.availableQty <= 0
                                      Text('${part.brand} ${part.deviceModel}'),
                                  subtitle:
                                  title: Text(part.partName),
                              .map((part) => ListTile(
                          children: items
                      : ListView(
                      ? const EmptyMessage('Sparepart belum tersedia.')
                  data: (items) => items.isEmpty
                spareparts.when(
              child: TabBarView(children: [
            Expanded(
            const TabBar(tabs: [Tab(text: 'Sparepart'), Tab(text: 'Ulasan')]),
            ),
                  ]),
                        'Rating ${store.ratingAvg.toStringAsFixed(1)} - ${store.phoneNumber}${store.verifiedAt != null ? ' - Verified' : ''}'),
                    Text(
                    const SizedBox(height: 8),
                    Text(store.address),
                            ?.copyWith(fontWeight: FontWeight.w800)),
                            .headlineSmall
                            .textTheme
                        style: Theme.of(context)
                    Text(store.storeName,
                  children: [
                  crossAxisAlignment: CrossAxisAlignment.start,
              child: Column(
              padding: const EdgeInsets.all(16),
            Padding(
          child: Column(children: [
          length: 2,
        builder: (store) => DefaultTabController(
        value: detail,
      child: AsyncPage(
          label: const Text('Buat Order')),
          icon: const Icon(Icons.add),
          onPressed: () => context.push('/booking/$storeId'),
      floatingActionButton: FloatingActionButton.extended(
      title: 'Detail Toko',
    return CustomerScaffold(
    final spareparts = ref.watch(sparepartsProvider(storeId));
    final detail = ref.watch(storeDetailProvider(storeId));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});
class StoreDetailScreen extends ConsumerWidget {

}
  }
    );
      ]),
                            .toList()))),
                                    context.push('/stores/${store.id}')))
                                onTap: () =>
                                store: store,
                            .map((store) => StoreCard(
                        children: items
                    : ListView(
                    ? const EmptyMessage('Toko tidak ditemukan.')
                builder: (items) => items.isEmpty
                value: stores,
            child: AsyncPage(
        Expanded(
        ),
              onSubmitted: (_) => setState(() {})),
                  border: OutlineInputBorder()),
                  hintText: 'Cari model perangkat',
                  prefixIcon: Icon(Icons.search),
              decoration: const InputDecoration(
              controller: _model,
          child: TextField(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        Padding(
        ),
                  .toList()),
                      ))
                            onSelected: (_) => setState(() => _brand = brand)),
                            selected: _brand == brand,
                            label: Text(brand),
                        child: FilterChip(
                            horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                  .map((brand) => Padding(
              children: ['All', ...brands]
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
          child: ListView(
          height: 54,
        SizedBox(
      child: Column(children: [
      title: 'Pilih Toko',
    return CustomerScaffold(
        ref.watch(storeListProvider((brand: _brand, model: _model.text)));
    final stores =
    brands.sort();
    final brands = deviceModels.valueOrNull?.map((group) => group.brand).toSet().toList() ?? const <String>[];
    final deviceModels = ref.watch(deviceModelsProvider);
  Widget build(BuildContext context) {
  @override
  final _model = TextEditingController();
  String _brand = 'All';
class _StoreListScreenState extends ConsumerState<StoreListScreen> {

}
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
  @override
  const StoreListScreen({super.key});
class StoreListScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ]),
              Text(label)
                      ?.copyWith(fontWeight: FontWeight.w900)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              Text(value,
            child: Column(children: [
            padding: const EdgeInsets.all(16),
          child: Padding(
          margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
  Widget build(BuildContext context) => Expanded(
  @override
  final String value;
  final String label;
  const _SummaryTile({required this.label, required this.value});
class _SummaryTile extends StatelessWidget {

}
  }
    );
      ),
        ),
          ],
            ),
              ),
                    style: TextStyle(fontWeight: FontWeight.w700)),
                    'Promo servis bulan ini: cek perangkat lebih cepat dan pantau progres langsung dari aplikasi.',
                child: Text(
                padding: EdgeInsets.all(18),
              child: const Padding(
              color: Theme.of(context).colorScheme.secondaryContainer,
              margin: const EdgeInsets.all(16),
            Card(
            ),
                  const EmptyMessage('Pesanan belum bisa dimuat.'),
              error: (_, __) =>
                  const SizedBox(height: 260, child: SkeletonList(count: 3)),
              loading: () =>
                          .toList()),
                              onTap: () => context.push('/orders/${order.id}')))
                              order: order,
                          .map((order) => OrderCard(
                      children: orders
                  : Column(
                  ? const EmptyMessage('Belum ada pesanan.')
              data: (orders) => orders.isEmpty
            recent.when(
                    child: const Text('Lihat Semua'))),
                    onPressed: () => context.push('/orders'),
                action: TextButton(
            SectionTitle('Pesanan Terbaru',
            ),
              ]),
                        label: const Text('Kupon'))),
                        icon: const Icon(Icons.local_offer),
                        onPressed: () => context.push('/coupons'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Pesanan'))),
                        icon: const Icon(Icons.inventory_2),
                        onPressed: () => context.push('/orders'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Servis'))),
                        icon: const Icon(Icons.build),
                        onPressed: () => context.push('/stores'),
                    child: FilledButton.icon(
                Expanded(
              child: Row(children: [
              padding: const EdgeInsets.all(16),
            Padding(
            ),
                  child: Text('Ringkasan belum tersedia.')),
                  padding: EdgeInsets.all(16),
              error: (_, __) => const Padding(
                  child: Center(child: CircularProgressIndicator())),
                  height: 88,
              loading: () => const SizedBox(
              ]),
                    label: 'Garansi', value: data.activeWarranties.toString()),
                _SummaryTile(
                    label: 'Kupon', value: data.activeCoupons.toString()),
                _SummaryTile(
                    label: 'Aktif', value: data.activeOrders.toString()),
                _SummaryTile(
              data: (data) => Row(children: [
            summary.when(
            ),
                      ?.copyWith(fontWeight: FontWeight.w800)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              child: Text('Halo, ${user?.fullName ?? 'Pelanggan'}!',
              padding: const EdgeInsets.all(16),
            Padding(
          children: [
          padding: const EdgeInsets.only(bottom: 24),
        child: ListView(
        },
          ref.invalidate(featuredStoresProvider);
          ref.invalidate(customerOrdersProvider('recent'));
          ref.invalidate(homeSummaryProvider);
        onRefresh: () async {
      child: RefreshIndicator(
      ],
            icon: const Icon(Icons.person_outline)),
            onPressed: () => context.push('/profile'),
        IconButton(
            icon: const Icon(Icons.notifications_outlined)),
            onPressed: () => context.push('/notifications'),
        IconButton(
      actions: [
      title: 'ServisGadget',
    return CustomerScaffold(
    final recent = ref.watch(customerOrdersProvider('recent'));
    final summary = ref.watch(homeSummaryProvider);
    final user = ref.watch(customerAuthProvider).valueOrNull;
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  const HomeScreen({super.key});
class HomeScreen extends ConsumerWidget {

}
      );
        ),
          ),
            ],
                      : const Text('Simpan Password')),
                      ? const CircularProgressIndicator()
                  child: _loading
                  onPressed: _loading ? null : _submit,
              FilledButton(
              const SizedBox(height: 20),
                      v != _next.text ? 'Konfirmasi tidak sama.' : null),
                  validator: (v) =>
                      border: OutlineInputBorder()),
                      labelText: 'Konfirmasi Password Baru',
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _confirm,
              TextFormField(
              const SizedBox(height: 12),
                  }),
                    return null;
                      return 'Password baru tidak boleh sama.';
                    if (v == _old.text)
                    if (v == null || v.length < 8) return 'Minimal 8 karakter.';
                  validator: (v) {
                      labelText: 'Password Baru', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _next,
              TextFormField(
              const SizedBox(height: 12),
                      v == null || v.isEmpty ? 'Wajib diisi.' : null),
                  validator: (v) =>
                      labelText: 'Password Lama', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _old,
              TextFormField(
              const SizedBox(height: 16),
                          'Ganti password sementaramu sebelum melanjutkan.'))),
                      child: Text(
                      padding: EdgeInsets.all(16),
                  child: const Padding(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.amber.withValues(alpha: 0.18),
              Material(
            children: [
            padding: const EdgeInsets.all(16),
          child: ListView(
          key: _formKey,
        child: Form(
        title: 'Ganti Password',
  Widget build(BuildContext context) => CustomerScaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      if (mounted) context.go('/home');
          .changePassword(_old.text, _next.text);
          .read(customerAuthProvider.notifier)
      await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  final _confirm = TextEditingController();
  final _next = TextEditingController();
  final _old = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {

}
      _ChangePasswordScreenState();
  ConsumerState<ChangePasswordScreen> createState() =>
  @override
  const ChangePasswordScreen({super.key});
class ChangePasswordScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ),
              ),
                ),
                  ],
                            : const Text('Masuk')),
                            ? const CircularProgressIndicator()
                        child: _loading
                        onPressed: _loading ? null : _submit,
                    FilledButton(
                    const SizedBox(height: 20),
                    ),
                          : null,
                          ? 'Password wajib diisi.'
                      validator: (value) => value == null || value.isEmpty
                      ),
                                : Icons.visibility_off)),
                                ? Icons.visibility
                            icon: Icon(_obscure
                                setState(() => _obscure = !_obscure),
                            onPressed: () =>
                        suffixIcon: IconButton(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        labelText: 'Password',
                      decoration: InputDecoration(
                      obscureText: _obscure,
                      controller: _password,
                    TextFormField(
                    const SizedBox(height: 12),
                    ),
                              : null,
                              ? 'Nomor HP wajib diisi.'
                          value == null || value.trim().isEmpty
                      validator: (value) =>
                          border: OutlineInputBorder()),
                          prefixIcon: Icon(Icons.phone),
                          labelText: 'Nomor HP',
                      decoration: const InputDecoration(
                      keyboardType: TextInputType.phone,
                      controller: _phone,
                    TextFormField(
                    const SizedBox(height: 24),
                        textAlign: TextAlign.center),
                        'Gunakan akun yang dikirim admin toko lewat WhatsApp.',
                    const Text(
                    const SizedBox(height: 8),
                            ?.copyWith(fontWeight: FontWeight.w800)),
                            .headlineSmall
                            .textTheme
                        style: Theme.of(context)
                        textAlign: TextAlign.center,
                    Text('Masuk ke ServisGadget',
                    const SizedBox(height: 16),
                    const Icon(Icons.handyman, size: 56),
                  children: [
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                child: ListView(
                key: _formKey,
              child: Form(
              constraints: const BoxConstraints(maxWidth: 420),
            child: ConstrainedBox(
          child: Center(
        body: SafeArea(
  Widget build(BuildContext context) => Scaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      context.go(result.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          .login(_phone.text, _password.text);
          .read(customerAuthProvider.notifier)
      final result = await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  bool _obscure = true;
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _LoginScreenState extends ConsumerState<LoginScreen> {

}
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
  @override
  const LoginScreen({super.key});
class LoginScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ),
            ),
              ),
                ],
                  const SizedBox(height: 32),
                  ),
                    ),
                      label: const Text('Admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      onPressed: () => context.push('/admin/login'),
                    child: OutlinedButton.icon(
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 12),
                  ),
                    ],
                      ),
                        ),
                          label: const Text('Toko'),
                          icon: const Icon(Icons.store_outlined, size: 20),
                          onPressed: () => context.push('/store-login'),
                        child: OutlinedButton.icon(
                      Expanded(
                      const SizedBox(width: 12),
                      ),
                        ),
                          label: const Text('Pelanggan'),
                          icon: const Icon(Icons.person_outline, size: 20),
                          onPressed: () => context.push('/login'),
                        child: OutlinedButton.icon(
                      Expanded(
                    children: [
                  Row(
                  const SizedBox(height: 14),
                  ),
                    ),
                          style: TextStyle(fontSize: 16)),
                      label: const Text('Service Now',
                      icon: const Icon(Icons.build, size: 22),
                      onPressed: () => context.go('/service'),
                    child: FilledButton.icon(
                    height: 52,
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 48),
                  ),
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    style: theme.textTheme.bodyLarge
                    'Servis smartphone cepat & terpercaya',
                  Text(
                  const SizedBox(height: 8),
                  ),
                        ?.copyWith(fontWeight: FontWeight.w800),
                    style: theme.textTheme.headlineLarge
                    'ServisGadget',
                  Text(
                  const SizedBox(height: 16),
                  Icon(Icons.build, size: 80, color: theme.colorScheme.primary),
                children: [
                mainAxisSize: MainAxisSize.min,
              child: Column(
              padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
            constraints: const BoxConstraints(maxWidth: 420),
          child: ConstrainedBox(
        child: Center(
      body: SafeArea(
    return Scaffold(
    final theme = Theme.of(context);
  Widget build(BuildContext context) {
  @override

  const WelcomeScreen({super.key});
class WelcomeScreen extends StatelessWidget {

}
      );
        ),
          ]),
            CircularProgressIndicator(),
            SizedBox(height: 24),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('ServisGadget',
            SizedBox(height: 16),
            Icon(Icons.handyman, size: 64),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        body: Center(
  Widget build(BuildContext context) => const Scaffold(
  @override

  }
    }
      if (mounted) context.go('/login');
      await ref.read(customerSessionProvider).clearAll();
    } catch (_) {
      context.go(user.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          await ref.read(customerAuthProvider.notifier).restoreSession();
      final user =
    try {
    }
      return;
      context.go('/login');
    if (token == null) {
    if (!mounted) return;
    final token = await ref.read(customerSessionProvider).readAccessToken();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  Future<void> _checkAuth() async {

  }
    Future.microtask(_checkAuth);
    super.initState();
  void initState() {
  @override
class _SplashScreenState extends ConsumerState<SplashScreen> {

}
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
  @override

  const SplashScreen({super.key});
class SplashScreen extends ConsumerStatefulWidget {

import '../widgets/customer_widgets.dart';
import '../../domain/customer_models.dart';
import '../../data/customer_repositories.dart';
import '../../application/customer_providers.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
}

}
      ]));
            title: Text('Nomor HP hanya dapat diubah melalui support.'))
            leading: Icon(Icons.verified_user),
        const ListTile(
            onTap: () => context.push('/change-password')),
            title: const Text('Ganti Password'),
            leading: const Icon(Icons.lock),
        ListTile(
      child: ListView(children: [
      title: 'Keamanan',
  Widget build(BuildContext context) => CustomerScaffold(
  @override
  const SecurityScreen({super.key});
class SecurityScreen extends StatelessWidget {

}
      );
                'Sesi aktif saat ini. Logout dari profil untuk menghapus sesi.')),
            subtitle: Text(
            title: Text('Perangkat ini'),
            leading: Icon(Icons.phone_android),
        child: ListTile(
        title: 'Sesi Login',
  Widget build(BuildContext context) => const CustomerScaffold(
  @override
  const SessionsScreen({super.key});
class SessionsScreen extends StatelessWidget {

}
  }
    );
      ),
        error: (_, __) => const EmptyMessage('Preferensi belum bisa dimuat.'),
        loading: () => const Center(child: CircularProgressIndicator()),
            }),
              ref.invalidate(notificationPreferenceProvider);
                  .saveNotificationPreference(next);
                  .read(customerSessionProvider)
              await ref
            onChanged: (next) async {
            value: value,
            title: const Text('Notifikasi WhatsApp dan aplikasi'),
        data: (value) => SwitchListTile(
      child: enabled.when(
      title: 'Preferensi Notifikasi',
    return CustomerScaffold(
    final enabled = ref.watch(notificationPreferenceProvider);
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  const NotificationPreferencesScreen({super.key});
class NotificationPreferencesScreen extends ConsumerWidget {

}
                ])));
                  Text(item!.message)
                  const SizedBox(height: 12),
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(item!.title,
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ? const EmptyMessage('Notifikasi tidak ditemukan.')
          child: item == null
          padding: const EdgeInsets.all(16),
      child: Padding(
      title: 'Detail Notifikasi',
  Widget build(BuildContext context) => CustomerScaffold(
  @override
  final NotificationItem? item;
  const NotificationDetailScreen({super.key, this.item});
class NotificationDetailScreen extends StatelessWidget {

}
      );
                        .toList())),
                                extra: item)))
                                '/notifications/${item.id}',
                            onTap: () => context.push(
                            subtitle: Text(item.message),
                            title: Text(item.title),
                                : Icons.mark_email_unread),
                                ? Icons.mark_email_read
                            leading: Icon(item.isRead
                        .map((item) => ListTile(
                    children: items
                : ListView(
                ? const EmptyMessage('Belum ada notifikasi.')
            builder: (items) => items.isEmpty
            value: ref.watch(notificationsProvider),
        child: AsyncPage(
        title: 'Notifikasi',
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
  @override
  const NotificationsScreen({super.key});
class NotificationsScreen extends ConsumerWidget {

}
      );
                        .toList())),
                        .map((coupon) => CouponRewardBanner(coupon: coupon))
                    children: items
                    padding: const EdgeInsets.all(16),
                : ListView(
                ? const EmptyMessage('Belum ada kupon.')
            builder: (items) => items.isEmpty
            value: ref.watch(couponsProvider),
        child: AsyncPage(
        title: 'Kupon Saya',
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
  @override
  const CouponsScreen({super.key});
class CouponsScreen extends ConsumerWidget {

}
  const SimpleListScreens._();
class SimpleListScreens {

}
  }
    );
      ]),
            }),
              if (context.mounted) context.go('/login');
              await ref.read(customerAuthProvider.notifier).logout();
            onTap: () async {
            iconColor: Colors.red,
            textColor: Colors.red,
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
        ListTile(
            onTap: () => context.push('/sessions')),
            title: const Text('Sesi Login'),
            leading: const Icon(Icons.devices),
        ListTile(
            onTap: () => context.push('/change-password')),
            title: const Text('Ganti Password'),
            leading: const Icon(Icons.lock),
        ListTile(
            onTap: () => context.push('/notification-preferences')),
            title: const Text('Preferensi Notifikasi'),
            leading: const Icon(Icons.notifications),
        ListTile(
            onTap: () => context.push('/coupons')),
            title: const Text('Kupon Saya'),
            leading: const Icon(Icons.local_offer),
        ListTile(
            onTap: () => context.push('/orders')),
            title: const Text('Pesanan Saya'),
            leading: const Icon(Icons.inventory),
        ListTile(
        const Divider(),
              onPressed: _loading ? null : _save, child: const Text('Simpan')),
          FilledButton(
        if (_dirty)
            onChanged: (_) => setState(() => _dirty = true)),
                labelText: 'Alamat', border: OutlineInputBorder()),
            decoration: const InputDecoration(
            maxLines: 4,
            minLines: 2,
            controller: _address,
        TextFormField(
        const SizedBox(height: 12),
                border: OutlineInputBorder())),
                labelText: 'Nomor HP (tidak bisa diubah)',
            decoration: const InputDecoration(
            readOnly: true,
            initialValue: user?.phoneNumber ?? '-',
        TextFormField(
        const SizedBox(height: 12),
            onChanged: (_) => setState(() => _dirty = true)),
                labelText: 'Nama Lengkap', border: OutlineInputBorder()),
            decoration: const InputDecoration(
            controller: _name,
        TextFormField(
        const SizedBox(height: 16),
                : 'S')),
                ? user!.fullName[0]
            child: Text((user?.fullName.isNotEmpty ?? false)
            radius: 44,
        CircleAvatar(
      child: ListView(padding: const EdgeInsets.all(16), children: [
      title: 'Profil',
    return CustomerScaffold(
    }
      _address.text = user.address ?? '';
      _name.text = user.fullName;
    if (user != null && !_dirty && _name.text.isEmpty) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      setState(() => _dirty = false);
          .updateProfile(fullName: _name.text, address: _address.text);
          .read(customerAuthProvider.notifier)
      await ref
    try {
    setState(() => _loading = true);
  Future<void> _save() async {

  bool _loading = false;
  bool _dirty = false;
  final _address = TextEditingController();
  final _name = TextEditingController();
class _ProfileScreenState extends ConsumerState<ProfileScreen> {

}
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
  @override
  const ProfileScreen({super.key});
class ProfileScreen extends ConsumerStatefulWidget {

}
  }
    );
          }),
            ]);
                  child: Text(_loading ? 'Mengirim...' : 'Kirim Klaim')),
                  onPressed: _loading ? null : _submit,
              FilledButton(
              const SizedBox(height: 20),
                      .toList()),
                          onDeleted: () => setState(() => _files.remove(file))))
                          label: Text(file.name),
                      .map((file) => InputChip(
                  children: _files
                  spacing: 8,
              Wrap(
                  label: const Text('Tambah Foto')),
                  icon: const Icon(Icons.add_a_photo),
                        },
                            setState(() => _files.add(picked));
                          if (picked != null)
                              maxWidth: 1600);
                              imageQuality: 72,
                              source: ImageSource.gallery,
                          final picked = await ImagePicker().pickImage(
                      : () async {
                      ? null
                  onPressed: _files.length >= 5
              OutlinedButton.icon(
              const SizedBox(height: 12),
                      border: OutlineInputBorder())),
                      labelText: 'Deskripsi Masalah',
                  decoration: const InputDecoration(
                  maxLines: 7,
                  minLines: 4,
                  controller: _description,
              TextField(
                  onChanged: (v) => setState(() => _type = v!)),
                  ],
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                        child: Text('Diagnosa Salah')),
                        value: 'wrong_diagnosis',
                    DropdownMenuItem(
                        child: Text('Kualitas Servis')),
                        value: 'service_quality',
                    DropdownMenuItem(
                        value: 'warranty_claim', child: Text('Klaim Garansi')),
                    DropdownMenuItem(
                  items: const [
                  decoration: const InputDecoration(labelText: 'Jenis Masalah'),
                  initialValue: _type,
              DropdownButtonFormField(
              Text('Garansi aktif s/d ${shortDate(data.warrantyExpiredAt)}'),
            return ListView(padding: const EdgeInsets.all(16), children: [
            }
                  'Garansi sudah berakhir pada ${shortDate(data.warrantyExpiredAt)}.');
              return EmptyMessage(
                DateTime.now().isAfter(data.warrantyExpiredAt!)) {
            if (data.warrantyExpiredAt == null ||
          builder: (data) {
          value: order,
      child: AsyncPage(
      title: 'Klaim Garansi',
    return CustomerScaffold(
    final order = ref.watch(orderDetailProvider(widget.orderId));
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      }
        context.pop();
                'Klaim diterima. Admin toko akan merespons dalam 24 jam.')));
            content: Text(
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      if (mounted) {
      ref.invalidate(orderDetailProvider(widget.orderId));
          evidenceUrls: urls);
          description: _description.text,
          disputeType: _type,
          orderId: widget.orderId,
      await ref.read(disputeRepositoryProvider).createDispute(
      }
            .uploadFile(file, 'evidence', null));
            .read(uploadRepositoryProvider)
        urls.add(await ref
      for (final file in _files) {
      final urls = <String>[];
    try {
    setState(() => _loading = true);
    }
      return;
          const SnackBar(content: Text('Deskripsi minimal 20 karakter.')));
      ScaffoldMessenger.of(context).showSnackBar(
    if (_description.text.length < 20) {
  Future<void> _submit() async {

  bool _loading = false;
  final _files = <XFile>[];
  String _type = 'warranty_claim';
  final _description = TextEditingController();
class _WarrantyClaimScreenState extends ConsumerState<WarrantyClaimScreen> {

}
      _WarrantyClaimScreenState();
  ConsumerState<WarrantyClaimScreen> createState() =>
  @override
  final String orderId;
  const WarrantyClaimScreen({super.key, required this.orderId});
class WarrantyClaimScreen extends ConsumerStatefulWidget {

}
      );
        ]),
              child: const Text('Kembali ke Pesanan')),
              onPressed: () => context.go('/orders'),
          OutlinedButton(
              child: const Text('Lihat Kupon Saya')),
              onPressed: () => context.go('/coupons'),
          FilledButton(
          if (result.coupon != null) CouponRewardBanner(coupon: result.coupon!),
                  ?.copyWith(fontWeight: FontWeight.w800)),
                  .headlineSmall
                  .textTheme
              style: Theme.of(context)
              textAlign: TextAlign.center,
          Text('Ulasan berhasil dikirim!',
          const Icon(Icons.celebration, size: 80, color: Colors.orange),
        child: ListView(padding: const EdgeInsets.all(24), children: [
        title: 'Ulasan Berhasil',
  Widget build(BuildContext context) => CustomerScaffold(
  @override
  final ReviewResult result;
  const ReviewSuccessScreen({super.key, required this.result});
class ReviewSuccessScreen extends StatelessWidget {

}
      );
        ]),
              child: Text(_loading ? 'Mengirim...' : 'Kirim Ulasan')),
              onPressed: _loading ? null : _submit,
          FilledButton(
                  labelText: 'Komentar', border: OutlineInputBorder())),
              decoration: const InputDecoration(
              maxLines: 6,
              minLines: 4,
              maxLength: 500,
              controller: _comment,
          TextField(
          const SizedBox(height: 16),
              textAlign: TextAlign.center),
              ][_rating],
                'Sangat Bagus'
                'Bagus',
                'Biasa',
                'Buruk',
                'Sangat Buruk',
                '',
              [
          Text(
                          color: Colors.amber)))),
                          index < _rating ? Icons.star : Icons.star_border,
                      icon: Icon(
                      onPressed: () => setState(() => _rating = index + 1),
                      iconSize: 38,
                  (index) => IconButton(
                  5,
              children: List.generate(
              mainAxisAlignment: MainAxisAlignment.center,
          Row(
        child: ListView(padding: const EdgeInsets.all(16), children: [
        title: 'Beri Ulasan',
  Widget build(BuildContext context) => CustomerScaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      if (mounted) context.go('/review-success', extra: result);
      ref.invalidate(orderDetailProvider(widget.orderId));
          orderId: widget.orderId, rating: _rating, comment: _comment.text);
      final result = await ref.read(reviewRepositoryProvider).createReview(
    try {
    setState(() => _loading = true);
  Future<void> _submit() async {
  bool _loading = false;
  int _rating = 5;
  final _comment = TextEditingController();
class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {

}
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
  @override
  final String orderId;
  const ReviewFormScreen({super.key, required this.orderId});
class ReviewFormScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        },
          ]);
                child: Text(_loading ? 'Mengirim...' : 'Kirim Pembayaran')),
                onPressed: _loading ? null : () => _submit(order),
            FilledButton(
            const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
            if (_progress > 0 && _progress < 1)
            if (_file != null) Text('Dipilih: ${_file!.name}'),
                label: Text(_file?.name ?? 'Ambil dari Galeri')),
                icon: const Icon(Icons.image),
                },
                  if (picked != null) setState(() => _file = picked);
                      maxWidth: 1600);
                      imageQuality: 72,
                      source: ImageSource.gallery,
                  final picked = await ImagePicker().pickImage(
                onPressed: () async {
            OutlinedButton.icon(
                label: const Text('Hapus Foto')),
                icon: const Icon(Icons.delete_outline),
                onPressed: () async => setState(() => _file = null),
            OutlinedButton.icon(
            const SizedBox(height: 12),
                decoration: const InputDecoration(labelText: 'Nominal')),
                keyboardType: TextInputType.number,
                controller: _amount,
            TextField(
                onChanged: (v) => setState(() => _type = v!)),
                ],
                      value: 'final_payment', child: Text('Pelunasan Final')),
                  DropdownMenuItem(
                  DropdownMenuItem(value: 'deposit', child: Text('Uang Muka')),
                items: const [
                    const InputDecoration(labelText: 'Jenis Pembayaran'),
                decoration:
                initialValue: _type,
            DropdownButtonFormField(
                onChanged: (v) => setState(() => _method = v!)),
                ],
                  DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                      value: 'transfer_bank', child: Text('Transfer Bank')),
                  DropdownMenuItem(
                items: const [
                    const InputDecoration(labelText: 'Metode Pembayaran'),
                decoration:
                initialValue: _method,
            DropdownButtonFormField(
            }),
              'Sisa': rupiah(due)
              'Sudah Bayar': rupiah(confirmed),
              'Final': rupiah(order.finalPrice ?? order.totalEstimasi),
              'Order': order.orderNumber,
            _InfoCard(title: 'Tagihan', rows: {
          return ListView(padding: const EdgeInsets.all(16), children: [
            _amount.text = due.clamp(0, double.infinity).toStringAsFixed(0);
          if (_amount.text.isEmpty)
          final due = (order.finalPrice ?? order.totalEstimasi) - confirmed;
              .fold<double>(0, (sum, p) => sum + p.amount);
              .where((p) => p.status == 'confirmed')
          final confirmed = order.payments
        builder: (order) {
        value: orderValue,
      child: AsyncPage(
      title: 'Pembayaran',
    return CustomerScaffold(
    final orderValue = ref.watch(orderDetailProvider(widget.orderId));
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      }
        context.pop();
            content: Text('Pembayaran dikirim, menunggu konfirmasi toko.')));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      if (mounted) {
      ref.invalidate(orderDetailProvider(order.id));
          proofUrl: proofUrl);
          type: _type,
          method: _method,
          amount: amount,
          orderId: order.id,
      await ref.read(paymentRepositoryProvider).createPayment(
              _file!, 'payments', (p) => setState(() => _progress = p));
          : await ref.read(uploadRepositoryProvider).uploadFile(
          ? null
      final proofUrl = _file == null
    try {
    setState(() => _loading = true);
    }
      return;
          const SnackBar(content: Text('Bukti transfer wajib diunggah.')));
      ScaffoldMessenger.of(context).showSnackBar(
    if (_method == 'transfer_bank' && _file == null) {
    if (amount <= 0) return;
        double.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final amount =
  Future<void> _submit(CustomerOrder order) async {

  bool _loading = false;
  double _progress = 0;
  XFile? _file;
  String _type = 'final_payment';
  String _method = 'transfer_bank';
  final _amount = TextEditingController();
class _PaymentUploadScreenState extends ConsumerState<PaymentUploadScreen> {

}
      _PaymentUploadScreenState();
  ConsumerState<PaymentUploadScreen> createState() =>
  @override
  final String orderId;
  const PaymentUploadScreen({super.key, required this.orderId});
class PaymentUploadScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        error: (error, _) => Center(child: Text(parseApiError(error))),
        loading: () => const SkeletonList(),
        ]),
              textAlign: TextAlign.center),
              'Diperbarui: ${DateFormat('HH:mm', 'id_ID').format(DateTime.now())}',
          Text(
          const SizedBox(height: 12),
          OrderStatusTimeline(entries: order.tracking),
        data: (order) => ListView(padding: const EdgeInsets.all(16), children: [
      child: tracking.when(
      title: 'Tracking',
    return CustomerScaffold(
    final tracking = ref.watch(orderTrackingProvider(orderId));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
class TrackingScreen extends ConsumerWidget {

}
      ]);
              label: const Text('Klaim Garansi')),
              icon: const Icon(Icons.shield),
                  context.push('/orders/${order.id}/warranty-claim'),
              onPressed: () =>
          OutlinedButton.icon(
            DateTime.now().isBefore(order.warrantyExpiredAt!))
            order.warrantyExpiredAt != null &&
        if (order.status == OrderStatus.completed &&
              label: const Text('Beri Ulasan')),
              icon: const Icon(Icons.star),
              onPressed: () => context.push('/orders/${order.id}/review'),
          FilledButton.icon(
        if (order.status == OrderStatus.completed && !order.reviewed)
              label: const Text('Upload Bukti Bayar')),
              icon: const Icon(Icons.payment),
              onPressed: () => context.push('/orders/${order.id}/payment'),
          FilledButton.icon(
        if (order.status == OrderStatus.waitingPayment)
  Widget build(BuildContext context) => Column(children: [
  @override
  final CustomerOrder order;
  const _OrderActions({required this.order});
class _OrderActions extends StatelessWidget {

}
      );
        ),
          ]),
            ]),
                      child: const Text('Tolak'))),
                      onPressed: _loading ? null : () => _approve(false),
                  child: OutlinedButton(
              Expanded(
              const SizedBox(width: 8),
                      child: const Text('Setuju'))),
                      onPressed: _loading ? null : () => _approve(true),
                  child: FilledButton(
              Expanded(
            Row(children: [
            const SizedBox(height: 12),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('Total: ${rupiah(widget.order.finalPrice ?? 0)}',
            const Divider(),
              Text('Service Fee: ${rupiah(widget.order.serviceFee!)}'),
            if (widget.order.serviceFee != null)
                '${item.serviceType}: ${rupiah(item.finalItemPrice ?? item.itemPrice)}')),
            ...widget.order.items.map((item) => Text(
            const SizedBox(height: 8),
              Text(widget.order.diagnosisNote!),
            if (widget.order.diagnosisNote != null)
                style: TextStyle(fontWeight: FontWeight.w900)),
            const Text('Hasil Diagnosa',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          child:
          padding: const EdgeInsets.all(16),
        child: Padding(
        color: Theme.of(context).colorScheme.primaryContainer,
  Widget build(BuildContext context) => Card(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      ref.invalidate(orderDetailProvider(widget.order.id));
      }
        await ref.read(orderRepositoryProvider).rejectOrder(widget.order.id);
      } else {
        await ref.read(orderRepositoryProvider).approveOrder(widget.order.id);
      if (approve) {
    try {
    setState(() => _loading = true);
  Future<void> _approve(bool approve) async {
  bool _loading = false;
class _DiagnosisApprovalCardState extends ConsumerState<DiagnosisApprovalCard> {

}
      _DiagnosisApprovalCardState();
  ConsumerState<DiagnosisApprovalCard> createState() =>
  @override
  final CustomerOrder order;
  const DiagnosisApprovalCard({super.key, required this.order});
class DiagnosisApprovalCard extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ]),
            _OrderActions(order: order),
                  subtitle: Text('${p.paymentMethod} - ${p.status}'))),
                  title: Text(rupiah(p.amount)),
              ...order.payments.map((p) => ListTile(
            else
              const Text('Belum ada pembayaran.')
            if (order.payments.isEmpty)
            const SectionTitle('Pembayaran'),
                child: const Text('Lihat Semua Tracking')),
                onPressed: () => context.push('/orders/$orderId/tracking'),
            TextButton(
            OrderStatusTimeline(entries: order.tracking.take(3).toList()),
            const SectionTitle('Tracking', action: null),
              DiagnosisApprovalCard(order: order),
            if (order.status == OrderStatus.waitingApproval)
                          'Batas waktu: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.slaDeadline!)}'))),
                      child: Text(
                      padding: const EdgeInsets.all(16),
                  child: Padding(
              Card(
            if (order.slaDeadline != null)
                trailing: Text(rupiah(item.finalItemPrice ?? item.itemPrice)))),
                subtitle: Text(item.complaint),
                title: Text(item.serviceType),
            ...order.items.map((item) => ListTile(
            const SectionTitle('Item Order'),
            }),
              if (order.finalPrice != null) 'Final': rupiah(order.finalPrice!)
                'Diskon': '-${rupiah(order.discountAmount)}',
              if (order.discountAmount > 0)
              'Estimasi': rupiah(order.totalEstimasi),
            _InfoCard(title: 'Harga', rows: {
            }),
              'Telepon': order.storePhone ?? '-'
              'Alamat': order.storeAddress ?? '-',
              'Nama': order.storeName ?? '-',
            _InfoCard(title: 'Toko', rows: {
            }),
                'Alamat': order.deliveryAddress!
              if (order.deliveryAddress != null)
              'Pengiriman': order.deliveryMethod,
              'Jenis': order.deviceType,
              'Model': order.deviceModel,
              'Brand': order.brand,
            _InfoCard(title: 'Perangkat', rows: {
            const SizedBox(height: 16),
            ]),
              StatusPill(order.status)
                          ?.copyWith(fontWeight: FontWeight.w800))),
                          .titleLarge
                          .textTheme
                      style: Theme.of(context)
                  child: SelectableText(order.orderNumber,
              Expanded(
            Row(children: [
          child: ListView(padding: const EdgeInsets.all(16), children: [
          onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
        builder: (order) => RefreshIndicator(
        value: orderValue,
      child: AsyncPage(
      title: 'Detail Pesanan',
    return CustomerScaffold(
    final orderValue = ref.watch(orderDetailProvider(orderId));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
class OrderDetailScreen extends ConsumerWidget {

}
  }
    );
                      .toList())),
                          onTap: () => context.push('/orders/${order.id}')))
                          order: order,
                      .map((order) => OrderCard(
                  children: items
              : ListView(
              ? const EmptyMessage('Tidak ada pesanan.')
          builder: (items) => items.isEmpty
          value: orders,
      child: AsyncPage(
      onRefresh: () async => ref.invalidate(customerOrdersProvider(group)),
    return RefreshIndicator(
    final orders = ref.watch(customerOrdersProvider(group));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String group;
  const _OrderTab(this.group);
class _OrderTab extends ConsumerWidget {

}
      );
        ),
          ]),
            ])),
              _OrderTab('cancelled')
              _OrderTab('completed'),
              _OrderTab('active'),
                child: TabBarView(children: [
            Expanded(
            ]),
              Tab(text: 'Dibatalkan')
              Tab(text: 'Selesai'),
              Tab(text: 'Aktif'),
            TabBar(tabs: [
          child: Column(children: [
          length: 3,
        child: DefaultTabController(
        title: 'Pesanan Saya',
  Widget build(BuildContext context) => const CustomerScaffold(
  @override
class _OrderListScreenState extends ConsumerState<OrderListScreen> {

}
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
  @override
  const OrderListScreen({super.key});
class OrderListScreen extends ConsumerStatefulWidget {

}
      );
        ]),
              child: const Text('Kembali ke Beranda')),
              onPressed: () => context.go('/home'),
          OutlinedButton(
              child: const Text('Lihat Pesanan Saya')),
              onPressed: () => context.go('/orders'),
          FilledButton(
          const SizedBox(height: 24),
                            'Cek WhatsApp kamu. Admin toko akan mengirimkan informasi akun ServisGadget.')))),
                        child: Text(
                        padding: EdgeInsets.all(16),
                    child: Padding(
                child: Card(
                padding: EdgeInsets.only(top: 16),
            const Padding(
          if (isNewCustomer)
              textAlign: TextAlign.center),
          const Text('Admin toko akan segera mengkonfirmasi perangkatmu.',
          const SizedBox(height: 16),
          SelectableText(orderNumber, textAlign: TextAlign.center),
          const SizedBox(height: 8),
                  ?.copyWith(fontWeight: FontWeight.w800)),
                  .headlineSmall
                  .textTheme
              style: Theme.of(context)
              textAlign: TextAlign.center,
          Text('Order berhasil dibuat!',
          const SizedBox(height: 16),
          const Icon(Icons.check_circle, size: 84, color: Colors.green),
        child: ListView(padding: const EdgeInsets.all(24), children: [
        title: 'Order Berhasil',
  Widget build(BuildContext context) => CustomerScaffold(
  @override
  final bool isNewCustomer;
  final String orderNumber;
      {super.key, required this.orderNumber, required this.isNewCustomer});
  const BookingSuccessScreen(
class BookingSuccessScreen extends StatelessWidget {

}
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
  String? _required(String? value) =>

  }
    );
      ),
            ]),
                      border: OutlineInputBorder())),
                      labelText: 'Kode Kupon (opsional)',
                  decoration: const InputDecoration(
                  controller: _coupon,
              TextFormField(
              const SizedBox(height: 12),
              ],
                    validator: _required),
                        border: OutlineInputBorder()),
                        labelText: 'Alamat Pickup',
                    decoration: const InputDecoration(
                    controller: _address,
                TextFormField(
                const SizedBox(height: 12),
              if (_delivery == 'courier_pickup') ...[
                      setState(() => _delivery = v.first)),
                  onSelectionChanged: (v) =>
                  ],
                        value: 'courier_pickup', label: Text('Pickup Kurir'))
                    ButtonSegment(
                        value: 'walk_in', label: Text('Antar Sendiri')),
                    ButtonSegment(
                  segments: const [
                  },
                    _delivery
                  selected: {
              SegmentedButton(
              const SectionTitle('Pengiriman'),
                  label: Text(_selectedPart?.partName ?? 'Pilih Sparepart')),
                  icon: const Icon(Icons.inventory),
                      spareparts.isEmpty ? null : () => _selectPart(spareparts),
                  onPressed:
              OutlinedButton.icon(
              const SizedBox(height: 12),
                      : null),
                      ? 'Minimal 10 karakter.'
                  validator: (v) => v == null || v.length < 10
                      border: OutlineInputBorder()),
                      labelText: 'Deskripsi kerusakan',
                  decoration: const InputDecoration(
                  maxLines: 5,
                  minLines: 3,
                  controller: _complaint,
              TextFormField(
              const SizedBox(height: 12),
                  onChanged: (v) => setState(() => _serviceType = v!)),
                  ],
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                    DropdownMenuItem(value: 'camera', child: Text('Kamera')),
                        value: 'charging_port', child: Text('Port')),
                    DropdownMenuItem(
                        value: 'battery_replacement', child: Text('Baterai')),
                    DropdownMenuItem(
                        value: 'screen_replacement', child: Text('Layar')),
                    DropdownMenuItem(
                  items: const [
                      labelText: 'Jenis Servis', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  value: _serviceType,
              DropdownButtonFormField(
              const SectionTitle('Kerusakan'),
                  validator: _required),
                      labelText: 'Model Device', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  controller: _model,
              TextFormField(
              const SizedBox(height: 12),
                  validator: _required),
                      labelText: 'Brand', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  controller: _brand,
              TextFormField(
              const SizedBox(height: 12),
                      setState(() => _deviceType = v.first)),
                  onSelectionChanged: (v) =>
                  ],
                    ButtonSegment(value: 'ios', label: Text('iOS'))
                    ButtonSegment(value: 'android', label: Text('Android')),
                  segments: const [
                  },
                    _deviceType
                  selected: {
              SegmentedButton(
              const SectionTitle('Info Perangkat'),
                  validator: _required),
                      labelText: 'Nomor HP', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  keyboardType: TextInputType.phone,
                  controller: _phone,
              TextFormField(
              const SizedBox(height: 12),
                  validator: _required),
                      labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  controller: _name,
              TextFormField(
              const SectionTitle('Info Pelanggan'),
            children: [
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: ListView(
        key: _form,
      child: Form(
      ),
                : 'Estimasi ${rupiah(_estimate)} - Buat Order')),
                ? 'Membuat order...'
            label: Text(_loading
            icon: const Icon(Icons.check),
            onPressed: _loading ? null : _submit,
        child: FilledButton.icon(
        margin: const EdgeInsets.only(left: 32),
        width: double.infinity,
      floatingActionButton: Container(
      title: 'Buat Order',
    return CustomerScaffold(
            const <SparePart>[];
        ref.watch(sparepartsProvider(widget.storeId)).valueOrNull ??
    final spareparts =
  Widget build(BuildContext context) {
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
          extra: result.isNewCustomer);
      context.go('/booking-success/${result.orderNumber}',
      if (!mounted) return;
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      );
        ],
              price: _estimate)
              sparepartId: _selectedPart?.id,
              complaint: _complaint.text,
              serviceType: _serviceType,
          CreateOrderItemInput(
        items: [
        couponCode: _coupon.text,
        deliveryAddress: _delivery == 'courier_pickup' ? _address.text : null,
        deliveryMethod: _delivery,
        deviceModel: _model.text,
        brand: _brand.text,
        deviceType: _deviceType,
        phoneNumber: normalizePhone(_phone.text),
        fullName: _name.text,
        storeId: widget.storeId,
      final req = CreateOrderRequest(
    try {
    setState(() => _loading = true);
    if (!_form.currentState!.validate()) return;
  Future<void> _submit() async {

  }
    if (part != null) setState(() => _selectedPart = part);
    );
      ),
            .toList(),
                ))
                      : () => Navigator.pop(context, part),
                      ? null
                  onTap: part.availableQty <= 0
                  trailing: Text(rupiah(part.price)),
                  subtitle: Text('${part.availableQty} tersedia'),
                  title: Text(part.partName),
                  enabled: part.availableQty > 0,
            .map((part) => ListTile(
        children: parts
        padding: const EdgeInsets.all(16),
      builder: (context) => ListView(
      context: context,
    final part = await showModalBottomSheet<SparePart>(
  Future<void> _selectPart(List<SparePart> parts) async {

  }
    }
      _address.text = user.address ?? '';
      _phone.text = user.phoneNumber;
      _name.text = user.fullName;
    if (user != null) {
    final user = ref.read(customerAuthProvider).valueOrNull;
    super.initState();
  void initState() {
  @override

  double get _estimate => _selectedPart?.price ?? 0;

  bool _loading = false;
  SparePart? _selectedPart;
  String _serviceType = 'screen_replacement';
  String _delivery = 'walk_in';
  String _deviceType = 'android';
  final _address = TextEditingController();
  final _coupon = TextEditingController();
  final _complaint = TextEditingController();
  final _model = TextEditingController();
  final _brand = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {

}
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
  @override
  final String storeId;
  const BookingFormScreen({super.key, required this.storeId});
class BookingFormScreen extends ConsumerStatefulWidget {

}
  );
    ),
      ]),
          )),
            label: Text(_loading ? 'Membuat...' : 'Buat Booking'),
            icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            onPressed: _loading ? null : _createBooking,
          Expanded(child: FilledButton.icon(
        if (_step == 4)
          )),
            label: Text(_step == 1 ? 'Cari Toko' : 'Lanjut'),
            icon: const Icon(Icons.arrow_forward),
            onPressed: _loading ? null : _nextStep,
          Expanded(child: FilledButton.icon(
        if (_step < 4)
        if (_step > 0) const SizedBox(width: 12),
          )),
            label: const Text('Kembali'),
            icon: const Icon(Icons.arrow_back),
            onPressed: _loading ? null : _prevStep,
          Expanded(child: OutlinedButton.icon(
        if (_step > 0)
      child: Row(children: [
      padding: const EdgeInsets.all(16),
    child: Padding(
  Widget _buildBottomNav(ThemeData theme) => SafeArea(

  );
    ]),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    padding: const EdgeInsets.symmetric(vertical: 6),
  Widget _confirmRow(ThemeData theme, String label, String value) => Padding(

  );
    ],
      ),
        decoration: const InputDecoration(labelText: 'Kode Kupon (opsional)', prefixIcon: Icon(Icons.local_offer_outlined), isDense: true),
        controller: _coupon,
      TextField(
      const SizedBox(height: 16),
      ),
        ),
          ]),
            Text('* Estimasi bersifat sementara, dapat berubah setelah diagnosis teknisi.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            ]),
              Text(rupiah(_estimateCost), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const Spacer(),
              Text('Estimasi Biaya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Row(children: [
            const Divider(height: 24),
            _confirmRow(theme, 'Pengiriman', _delivery == 'walk_in' ? 'Antar ke Toko' : 'Pickup Kurir'),
            const Divider(),
            ],
              _confirmRow(theme, 'Alamat', _address.text),
              const Divider(),
            if (_delivery == 'courier_pickup') ...[
            _confirmRow(theme, 'WhatsApp', _phone.text),
            const Divider(),
            _confirmRow(theme, 'Nama', _name.text),
            const Divider(),
            _confirmRow(theme, 'Keluhan', _complaint.text),
            const Divider(),
            _confirmRow(theme, 'Layanan', _serviceTypeLabels[_serviceType]!),
            const Divider(),
            _confirmRow(theme, 'Perangkat', '${_deviceType.toUpperCase()} - ${_selectedBrand ?? '-'} ${_selectedModel ?? '-'}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          padding: const EdgeInsets.all(16),
        child: Padding(
      Card(
      const SizedBox(height: 16),
      Text('Konfirmasi Booking', style: theme.textTheme.titleLarge),
    children: [
    padding: const EdgeInsets.all(16),
  Widget _buildStep5(ThemeData theme) => ListView(

  );
    ],
      ],
        ),
          decoration: const InputDecoration(labelText: 'Alamat Penjemputan', prefixIcon: Icon(Icons.location_on_outlined), alignLabelWithHint: true),
          controller: _address, maxLines: 2, textCapitalization: TextCapitalization.sentences,
        TextField(
        const SizedBox(height: 16),
      if (_delivery == 'courier_pickup') ...[
      ),
        decoration: const InputDecoration(labelText: 'Nomor WhatsApp', prefixText: '08', prefixIcon: Icon(Icons.phone_outlined)),
        controller: _phone, keyboardType: TextInputType.phone,
      TextField(
      const SizedBox(height: 16),
      ),
        decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
        controller: _name, textCapitalization: TextCapitalization.words,
      TextField(
      const SizedBox(height: 24),
      ),
        showSelectedIcon: false,
        onSelectionChanged: (v) => setState(() => _delivery = v.first),
        selected: {_delivery},
        ],
          ButtonSegment(value: 'courier_pickup', label: Text('Pickup Kurir'), icon: Icon(Icons.local_shipping)),
          ButtonSegment(value: 'walk_in', label: Text('Antar ke Toko'), icon: Icon(Icons.store)),
        segments: const [
      SegmentedButton<String>(
      const SizedBox(height: 24),
      Text('Data Diri & Pengiriman', style: theme.textTheme.titleLarge),
    children: [
    padding: const EdgeInsets.all(16),
  Widget _buildStep4(ThemeData theme) => ListView(

  }
    );
      ],
        }),
          );
            ),
              ),
                ]),
                  ]),
                    Text('Estimasi awal: ${rupiah(store.estimatedCost)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.info_outline, size: 16),
                  Row(children: [
                  const Divider(height: 16),
                  )),
                    ]),
                      Text(rupiah(sp.price), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      ),
                        child: Text(sp.status == 'available' ? 'Tersedia' : 'Preorder', style: TextStyle(fontSize: 11, color: sp.status == 'available' ? Colors.green : Colors.orange)),
                        ),
                          borderRadius: BorderRadius.circular(4),
                          color: sp.status == 'available' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        decoration: BoxDecoration(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      Container(
                      Expanded(child: Text(sp.partName, style: theme.textTheme.bodyMedium)),
                      const SizedBox(width: 8),
                      const Icon(Icons.build, size: 14),
                    child: Row(children: [
                    padding: const EdgeInsets.only(top: 4),
                  ...store.spareparts.map((sp) => Padding(
                  const SizedBox(height: 8),
                  ),
                    child: Text('${store.totalCompleted} servis selesai', style: theme.textTheme.labelSmall),
                    ),
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.tertiaryContainer,
                    decoration: BoxDecoration(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  Container(
                  const SizedBox(height: 8),
                  ]),
                    Expanded(child: Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  Row(children: [
                  const SizedBox(height: 4),
                  ]),
                    ]),
                      Text(store.ratingAvg.toStringAsFixed(1), style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                    Row(children: [
                    Expanded(child: Text(store.storeName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                  Row(children: [
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                padding: const EdgeInsets.all(16),
              child: Padding(
              onTap: () => _selectStore(store),
              borderRadius: BorderRadius.circular(12),
            child: InkWell(
            ),
              side: selected ? BorderSide(color: theme.colorScheme.primary) : BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            shape: RoundedRectangleBorder(
            color: selected ? theme.colorScheme.primaryContainer : null,
            margin: const EdgeInsets.only(bottom: 12),
          return Card(
          final selected = store.storeId == _selectedStoreId;
        ..._matchedStores.map((store) {
        const SizedBox(height: 16),
        Text('${_matchedStores.length} toko tersedia untuk perangkat kamu.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Pilih Toko Mitra', style: theme.textTheme.titleLarge),
      children: [
      padding: const EdgeInsets.all(16),
    return ListView(
    }
      );
        ],
          ),
            label: const Text('Kembali'),
            icon: const Icon(Icons.arrow_back),
            onPressed: _prevStep,
          FilledButton.icon(
          const SizedBox(height: 24),
          Text('Silakan periksa kembali brand, tipe, atau jenis layanan yang dipilih.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Text('Tidak ada toko yang cocok untuk perangkat ${_selectedBrand ?? '-'} ${_selectedModel ?? '-'} dengan layanan ini.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 24),
          Text('Rekomendasi Toko Mitra', style: theme.textTheme.titleLarge),
        children: [
        padding: const EdgeInsets.all(16),
      return ListView(
    if (_matchedStores.isEmpty) {
    }
      return const Center(child: CircularProgressIndicator());
    if (_loading && _matchedStores.isEmpty) {
  Widget _buildStep3(ThemeData theme) {

  );
    ],
      ),
        ),
          alignLabelWithHint: true,
          prefixIcon: Padding(padding: EdgeInsets.only(bottom: 64), child: Icon(Icons.report_problem_outlined)),
          hintText: 'Jelaskan kerusakan yang dialami, contoh:\n- Layar retak dari pojok kiri bawah\n- Baterai cepat habis (health < 70%)\n- Bootloop, tidak bisa masuk home screen',
          labelText: 'Keluhan / Deskripsi Kerusakan',
        decoration: const InputDecoration(
        controller: _complaint, maxLines: 4, textCapitalization: TextCapitalization.sentences,
      TextField(
      const SizedBox(height: 24),
      ),
        )).toList(),
          onSelected: (v) { if (v) setState(() => _serviceType = e.key); },
          selected: _serviceType == e.key,
          label: Text(e.value),
        children: _serviceTypeLabels.entries.map((e) => ChoiceChip(
        spacing: 8, runSpacing: 8,
      Wrap(
      const SizedBox(height: 24),
      Text('Pilih jenis layanan yang dibutuhkan dan jelaskan keluhannya.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      Text('Jenis Kerusakan / Layanan', style: theme.textTheme.titleLarge),
    children: [
    padding: const EdgeInsets.all(16),
  Widget _buildStep2(ThemeData theme) => ListView(

  }
    );
      ],
        ),
          },
            ]);
              ),
                onChanged: _selectedBrand == null ? null : (value) => setState(() => _selectedModel = value),
                items: models.map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                decoration: const InputDecoration(labelText: 'Tipe Smartphone', prefixIcon: Icon(Icons.smartphone)),
                value: modelValue,
              DropdownButtonFormField<String>(
              const SizedBox(height: 16),
              ),
                }),
                  _selectedModel = null;
                  _selectedBrand = value;
                onChanged: (value) => setState(() {
                items: brands.map((brand) => DropdownMenuItem(value: brand, child: Text(brand))).toList(),
                decoration: const InputDecoration(labelText: 'Brand Smartphone', prefixIcon: Icon(Icons.branding_watermark)),
                value: brandValue,
              DropdownButtonFormField<String>(
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            final modelValue = models.contains(_selectedModel) ? _selectedModel : null;
            final brandValue = brands.contains(_selectedBrand) ? _selectedBrand : null;
                : (selectedGroups.first.models.toSet().toList()..sort());
                ? const <String>[]
            final models = selectedGroups.isEmpty
            final selectedGroups = groups.where((group) => group.brand == _selectedBrand).toList();
            final brands = groups.map((group) => group.brand).toSet().toList()..sort();

            }
              return const EmptyMessage('Belum ada sparepart tersedia');
            if (groups.isEmpty) {
          data: (groups) {
          error: (error, _) => Text('Gagal memuat daftar perangkat: $error', style: TextStyle(color: theme.colorScheme.error)),
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
        deviceModels.when(
        const SizedBox(height: 24),
        ),
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _deviceType = v.first),
          selected: {_deviceType},
          ],
            ButtonSegment(value: 'ios', label: Text('iPhone / iOS'), icon: Icon(Icons.phone_iphone)),
            ButtonSegment(value: 'android', label: Text('Android'), icon: Icon(Icons.android)),
          segments: const [
        SegmentedButton<String>(
        const SizedBox(height: 24),
        Text('Pilih jenis smartphone lalu pilih brand dan tipe yang tersedia dari data sparepart toko.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Pilih Jenis & Tipe Perangkat', style: theme.textTheme.titleLarge),
      children: [
      padding: const EdgeInsets.all(16),
    return ListView(

    final deviceModels = ref.watch(deviceModelsProvider);
  Widget _buildStep1(ThemeData theme) {

  }
    );
      ),
        ),
          ],
            _buildBottomNav(theme),
            ),
              ),
                ],
                  _buildStep5(theme),
                  _buildStep4(theme),
                  _buildStep3(theme),
                  _buildStep2(theme),
                  _buildStep1(theme),
                children: [
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
              child: PageView(
            Expanded(
            const Divider(),
            ),
              ),
                }),
                  );
                    ]),
                      Text(steps[i], style: TextStyle(fontSize: 10, color: active || done ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      ),
                        ),
                            : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : theme.colorScheme.onSurfaceVariant)),
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                          child: done
                        child: Center(
                        ),
                          color: done ? theme.colorScheme.primary : active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        decoration: BoxDecoration(
                        width: 28, height: 28,
                      Container(
                    child: Column(children: [
                  return Expanded(
                  final done = i < _step;
                  final active = i == _step;
                children: List.generate(steps.length, (i) {
              child: Row(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            Padding(
          children: [
        child: Column(
      body: SafeArea(
      ),
        ),
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back),
        leading: IconButton(
        title: const Text('Service Now'),
      appBar: AppBar(
    return Scaffold(

    final steps = ['Perangkat', 'Kerusakan', 'Toko', 'Data Diri', 'Konfirmasi'];
    final theme = Theme.of(context);
  Widget build(BuildContext context) {
  @override

  }
    setState(() => _step -= 1);
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _pageController.previousPage(
    if (_step <= 0) return;
  void _prevStep() {

  }
    setState(() => _step += 1);
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _pageController.nextPage(

    }
      return;
      });
        }
          setState(() => _step = 2);
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          _pageController.nextPage(
        if (mounted) {
      _matchStores().then((_) {
    if (_step == 1) {

    if (_step == 3 && (_name.text.isEmpty || _phone.text.isEmpty)) return;
    if (_step == 2 && _selectedStoreId == null) return;
    if (_step == 1 && _complaint.text.isEmpty) return;
    if (_step == 0 && (_selectedBrand == null || _selectedModel == null)) return;
    if (_step >= 4) return;
  void _nextStep() {

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
      }
        );
          SnackBar(content: Text(parseApiError(error))),
        ScaffoldMessenger.of(context).showSnackBar(
      if (mounted) {
    } catch (error) {
      context.go('/booking-success/${result.orderNumber}', extra: result.isNewCustomer);
      if (!mounted) return;
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      );
        ],
          ),
            price: _estimateCost,
            sparepartId: _selectedPartId,
            complaint: _complaint.text.trim(),
            serviceType: _serviceType,
          CreateOrderItemInput(
        items: [
        couponCode: _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
        deliveryAddress: _delivery == 'courier_pickup' ? _address.text.trim() : null,
        deliveryMethod: _delivery,
        deviceModel: _selectedModel!,
        brand: _selectedBrand!,
        deviceType: _deviceType,
        phoneNumber: normalizePhone(_phone.text.trim()),
        fullName: _name.text.trim(),
        storeId: _selectedStoreId!,
      final req = CreateOrderRequest(
    try {
    setState(() => _loading = true);
  Future<void> _createBooking() async {

  }
    });
      _estimateCost = store.estimatedCost;
      _selectedStoreId = store.storeId;
    setState(() {
  void _selectStore(StoreMatchResult store) {

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
      _matchedStores = const [];
    } catch (_) {
      );
        partType: _serviceType,
        deviceModel: _selectedModel!,
        brand: _selectedBrand!,
      _matchedStores = await repo.matchStores(
      final repo = ref.read(storeDiscoveryRepositoryProvider);
    try {
    setState(() => _loading = true);
    if (_selectedBrand == null || _selectedModel == null) return;
  Future<void> _matchStores() async {

  }
    super.dispose();
    _coupon.dispose();
    _address.dispose();
    _phone.dispose();
    _name.dispose();
    _complaint.dispose();
    _pageController.dispose();
  void dispose() {
  @override

  }
    }
      _address.text = user.address ?? '';
      _phone.text = user.phoneNumber;
      _name.text = user.fullName;
    if (user != null) {
    final user = ref.read(customerAuthProvider).valueOrNull;
    super.initState();
  void initState() {
  @override

  };
    'other': 'Lainnya',
    'camera': 'Kamera',
    'charging_port': 'Port Charger',
    'battery_replacement': 'Ganti Baterai',
    'screen_replacement': 'Ganti Layar',
  final _serviceTypeLabels = const {

  List<StoreMatchResult> _matchedStores = const [];
  bool _loading = false;
  double _estimateCost = 0;
  String? _selectedPartId;
  String? _selectedStoreId;
  String _delivery = 'walk_in';
  String _serviceType = 'screen_replacement';
  String _deviceType = 'android';
  final _coupon = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _complaint = TextEditingController();
  String? _selectedModel;
  String? _selectedBrand;
  int _step = 0;
  final _pageController = PageController();
class _ServiceFlowScreenState extends ConsumerState<ServiceFlowScreen> {

}
  ConsumerState<ServiceFlowScreen> createState() => _ServiceFlowScreenState();
  @override
  const ServiceFlowScreen({super.key});
class ServiceFlowScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ]),
            ),
              ]),
                            .toList()),
                                    Text(review.comment ?? 'Tanpa komentar')))
                                subtitle:
                                title: Text('${review.rating}/5'),
                            .map((review) => ListTile(
                        children: store.reviews
                    : ListView(
                    ? const EmptyMessage('Belum ada ulasan.')
                store.reviews.isEmpty
                ),
                      const EmptyMessage('Sparepart gagal dimuat.'),
                  error: (_, __) =>
                  loading: () => const SkeletonList(),
                              .toList()),
                                      : rupiah(part.price))))
                                      ? 'Habis'
                                  trailing: Text(part.availableQty <= 0
                                      Text('${part.brand} ${part.deviceModel}'),
                                  subtitle:
                                  title: Text(part.partName),
                              .map((part) => ListTile(
                          children: items
                      : ListView(
                      ? const EmptyMessage('Sparepart belum tersedia.')
                  data: (items) => items.isEmpty
                spareparts.when(
              child: TabBarView(children: [
            Expanded(
            const TabBar(tabs: [Tab(text: 'Sparepart'), Tab(text: 'Ulasan')]),
            ),
                  ]),
                        'Rating ${store.ratingAvg.toStringAsFixed(1)} - ${store.phoneNumber}${store.verifiedAt != null ? ' - Verified' : ''}'),
                    Text(
                    const SizedBox(height: 8),
                    Text(store.address),
                            ?.copyWith(fontWeight: FontWeight.w800)),
                            .headlineSmall
                            .textTheme
                        style: Theme.of(context)
                    Text(store.storeName,
                  children: [
                  crossAxisAlignment: CrossAxisAlignment.start,
              child: Column(
              padding: const EdgeInsets.all(16),
            Padding(
          child: Column(children: [
          length: 2,
        builder: (store) => DefaultTabController(
        value: detail,
      child: AsyncPage(
          label: const Text('Buat Order')),
          icon: const Icon(Icons.add),
          onPressed: () => context.push('/booking/$storeId'),
      floatingActionButton: FloatingActionButton.extended(
      title: 'Detail Toko',
    return CustomerScaffold(
    final spareparts = ref.watch(sparepartsProvider(storeId));
    final detail = ref.watch(storeDetailProvider(storeId));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});
class StoreDetailScreen extends ConsumerWidget {

}
  }
    );
      ]),
                            .toList()))),
                                    context.push('/stores/${store.id}')))
                                onTap: () =>
                                store: store,
                            .map((store) => StoreCard(
                        children: items
                    : ListView(
                    ? const EmptyMessage('Toko tidak ditemukan.')
                builder: (items) => items.isEmpty
                value: stores,
            child: AsyncPage(
        Expanded(
        ),
              onSubmitted: (_) => setState(() {})),
                  border: OutlineInputBorder()),
                  hintText: 'Cari model perangkat',
                  prefixIcon: Icon(Icons.search),
              decoration: const InputDecoration(
              controller: _model,
          child: TextField(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        Padding(
        ),
                  .toList()),
                      ))
                            onSelected: (_) => setState(() => _brand = brand)),
                            selected: _brand == brand,
                            label: Text(brand),
                        child: FilterChip(
                            horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                  .map((brand) => Padding(
              children: ['All', ...brands]
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
          child: ListView(
          height: 54,
        SizedBox(
      child: Column(children: [
      title: 'Pilih Toko',
    return CustomerScaffold(
        ref.watch(storeListProvider((brand: _brand, model: _model.text)));
    final stores =
    brands.sort();
    final brands = deviceModels.valueOrNull?.map((group) => group.brand).toSet().toList() ?? const <String>[];
    final deviceModels = ref.watch(deviceModelsProvider);
  Widget build(BuildContext context) {
  @override
  final _model = TextEditingController();
  String _brand = 'All';
class _StoreListScreenState extends ConsumerState<StoreListScreen> {

}
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
  @override
  const StoreListScreen({super.key});
class StoreListScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ]),
              Text(label)
                      ?.copyWith(fontWeight: FontWeight.w900)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              Text(value,
            child: Column(children: [
            padding: const EdgeInsets.all(16),
          child: Padding(
          margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
  Widget build(BuildContext context) => Expanded(
  @override
  final String value;
  final String label;
  const _SummaryTile({required this.label, required this.value});
class _SummaryTile extends StatelessWidget {

}
  }
    );
      ),
        ),
          ],
            ),
              ),
                    style: TextStyle(fontWeight: FontWeight.w700)),
                    'Promo servis bulan ini: cek perangkat lebih cepat dan pantau progres langsung dari aplikasi.',
                child: Text(
                padding: EdgeInsets.all(18),
              child: const Padding(
              color: Theme.of(context).colorScheme.secondaryContainer,
              margin: const EdgeInsets.all(16),
            Card(
            ),
                  const EmptyMessage('Pesanan belum bisa dimuat.'),
              error: (_, __) =>
                  const SizedBox(height: 260, child: SkeletonList(count: 3)),
              loading: () =>
                          .toList()),
                              onTap: () => context.push('/orders/${order.id}')))
                              order: order,
                          .map((order) => OrderCard(
                      children: orders
                  : Column(
                  ? const EmptyMessage('Belum ada pesanan.')
              data: (orders) => orders.isEmpty
            recent.when(
                    child: const Text('Lihat Semua'))),
                    onPressed: () => context.push('/orders'),
                action: TextButton(
            SectionTitle('Pesanan Terbaru',
            ),
              ]),
                        label: const Text('Kupon'))),
                        icon: const Icon(Icons.local_offer),
                        onPressed: () => context.push('/coupons'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Pesanan'))),
                        icon: const Icon(Icons.inventory_2),
                        onPressed: () => context.push('/orders'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Servis'))),
                        icon: const Icon(Icons.build),
                        onPressed: () => context.push('/stores'),
                    child: FilledButton.icon(
                Expanded(
              child: Row(children: [
              padding: const EdgeInsets.all(16),
            Padding(
            ),
                  child: Text('Ringkasan belum tersedia.')),
                  padding: EdgeInsets.all(16),
              error: (_, __) => const Padding(
                  child: Center(child: CircularProgressIndicator())),
                  height: 88,
              loading: () => const SizedBox(
              ]),
                    label: 'Garansi', value: data.activeWarranties.toString()),
                _SummaryTile(
                    label: 'Kupon', value: data.activeCoupons.toString()),
                _SummaryTile(
                    label: 'Aktif', value: data.activeOrders.toString()),
                _SummaryTile(
              data: (data) => Row(children: [
            summary.when(
            ),
                      ?.copyWith(fontWeight: FontWeight.w800)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              child: Text('Halo, ${user?.fullName ?? 'Pelanggan'}!',
              padding: const EdgeInsets.all(16),
            Padding(
          children: [
          padding: const EdgeInsets.only(bottom: 24),
        child: ListView(
        },
          ref.invalidate(featuredStoresProvider);
          ref.invalidate(customerOrdersProvider('recent'));
          ref.invalidate(homeSummaryProvider);
        onRefresh: () async {
      child: RefreshIndicator(
      ],
            icon: const Icon(Icons.person_outline)),
            onPressed: () => context.push('/profile'),
        IconButton(
            icon: const Icon(Icons.notifications_outlined)),
            onPressed: () => context.push('/notifications'),
        IconButton(
      actions: [
      title: 'ServisGadget',
    return CustomerScaffold(
    final recent = ref.watch(customerOrdersProvider('recent'));
    final summary = ref.watch(homeSummaryProvider);
    final user = ref.watch(customerAuthProvider).valueOrNull;
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  const HomeScreen({super.key});
class HomeScreen extends ConsumerWidget {

}
      );
        ),
          ),
            ],
                      : const Text('Simpan Password')),
                      ? const CircularProgressIndicator()
                  child: _loading
                  onPressed: _loading ? null : _submit,
              FilledButton(
              const SizedBox(height: 20),
                      v != _next.text ? 'Konfirmasi tidak sama.' : null),
                  validator: (v) =>
                      border: OutlineInputBorder()),
                      labelText: 'Konfirmasi Password Baru',
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _confirm,
              TextFormField(
              const SizedBox(height: 12),
                  }),
                    return null;
                      return 'Password baru tidak boleh sama.';
                    if (v == _old.text)
                    if (v == null || v.length < 8) return 'Minimal 8 karakter.';
                  validator: (v) {
                      labelText: 'Password Baru', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _next,
              TextFormField(
              const SizedBox(height: 12),
                      v == null || v.isEmpty ? 'Wajib diisi.' : null),
                  validator: (v) =>
                      labelText: 'Password Lama', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _old,
              TextFormField(
              const SizedBox(height: 16),
                          'Ganti password sementaramu sebelum melanjutkan.'))),
                      child: Text(
                      padding: EdgeInsets.all(16),
                  child: const Padding(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.amber.withValues(alpha: 0.18),
              Material(
            children: [
            padding: const EdgeInsets.all(16),
          child: ListView(
          key: _formKey,
        child: Form(
        title: 'Ganti Password',
  Widget build(BuildContext context) => CustomerScaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      if (mounted) context.go('/home');
          .changePassword(_old.text, _next.text);
          .read(customerAuthProvider.notifier)
      await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  final _confirm = TextEditingController();
  final _next = TextEditingController();
  final _old = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {

}
      _ChangePasswordScreenState();
  ConsumerState<ChangePasswordScreen> createState() =>
  @override
  const ChangePasswordScreen({super.key});
class ChangePasswordScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ),
              ),
                ),
                  ],
                            : const Text('Masuk')),
                            ? const CircularProgressIndicator()
                        child: _loading
                        onPressed: _loading ? null : _submit,
                    FilledButton(
                    const SizedBox(height: 20),
                    ),
                          : null,
                          ? 'Password wajib diisi.'
                      validator: (value) => value == null || value.isEmpty
                      ),
                                : Icons.visibility_off)),
                                ? Icons.visibility
                            icon: Icon(_obscure
                                setState(() => _obscure = !_obscure),
                            onPressed: () =>
                        suffixIcon: IconButton(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        labelText: 'Password',
                      decoration: InputDecoration(
                      obscureText: _obscure,
                      controller: _password,
                    TextFormField(
                    const SizedBox(height: 12),
                    ),
                              : null,
                              ? 'Nomor HP wajib diisi.'
                          value == null || value.trim().isEmpty
                      validator: (value) =>
                          border: OutlineInputBorder()),
                          prefixIcon: Icon(Icons.phone),
                          labelText: 'Nomor HP',
                      decoration: const InputDecoration(
                      keyboardType: TextInputType.phone,
                      controller: _phone,
                    TextFormField(
                    const SizedBox(height: 24),
                        textAlign: TextAlign.center),
                        'Gunakan akun yang dikirim admin toko lewat WhatsApp.',
                    const Text(
                    const SizedBox(height: 8),
                            ?.copyWith(fontWeight: FontWeight.w800)),
                            .headlineSmall
                            .textTheme
                        style: Theme.of(context)
                        textAlign: TextAlign.center,
                    Text('Masuk ke ServisGadget',
                    const SizedBox(height: 16),
                    const Icon(Icons.handyman, size: 56),
                  children: [
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                child: ListView(
                key: _formKey,
              child: Form(
              constraints: const BoxConstraints(maxWidth: 420),
            child: ConstrainedBox(
          child: Center(
        body: SafeArea(
  Widget build(BuildContext context) => Scaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      context.go(result.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          .login(_phone.text, _password.text);
          .read(customerAuthProvider.notifier)
      final result = await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  bool _obscure = true;
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _LoginScreenState extends ConsumerState<LoginScreen> {

}
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
  @override
  const LoginScreen({super.key});
class LoginScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ),
            ),
              ),
                ],
                  const SizedBox(height: 32),
                  ),
                    ),
                      label: const Text('Admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      onPressed: () => context.push('/admin/login'),
                    child: OutlinedButton.icon(
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 12),
                  ),
                    ],
                      ),
                        ),
                          label: const Text('Toko'),
                          icon: const Icon(Icons.store_outlined, size: 20),
                          onPressed: () => context.push('/store-login'),
                        child: OutlinedButton.icon(
                      Expanded(
                      const SizedBox(width: 12),
                      ),
                        ),
                          label: const Text('Pelanggan'),
                          icon: const Icon(Icons.person_outline, size: 20),
                          onPressed: () => context.push('/login'),
                        child: OutlinedButton.icon(
                      Expanded(
                    children: [
                  Row(
                  const SizedBox(height: 14),
                  ),
                    ),
                          style: TextStyle(fontSize: 16)),
                      label: const Text('Service Now',
                      icon: const Icon(Icons.build, size: 22),
                      onPressed: () => context.go('/service'),
                    child: FilledButton.icon(
                    height: 52,
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 48),
                  ),
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    style: theme.textTheme.bodyLarge
                    'Servis smartphone cepat & terpercaya',
                  Text(
                  const SizedBox(height: 8),
                  ),
                        ?.copyWith(fontWeight: FontWeight.w800),
                    style: theme.textTheme.headlineLarge
                    'ServisGadget',
                  Text(
                  const SizedBox(height: 16),
                  Icon(Icons.build, size: 80, color: theme.colorScheme.primary),
                children: [
                mainAxisSize: MainAxisSize.min,
              child: Column(
              padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
            constraints: const BoxConstraints(maxWidth: 420),
          child: ConstrainedBox(
        child: Center(
      body: SafeArea(
    return Scaffold(
    final theme = Theme.of(context);
  Widget build(BuildContext context) {
  @override

  const WelcomeScreen({super.key});
class WelcomeScreen extends StatelessWidget {

}
      );
        ),
          ]),
            CircularProgressIndicator(),
            SizedBox(height: 24),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('ServisGadget',
            SizedBox(height: 16),
            Icon(Icons.handyman, size: 64),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        body: Center(
  Widget build(BuildContext context) => const Scaffold(
  @override

  }
    }
      if (mounted) context.go('/login');
      await ref.read(customerSessionProvider).clearAll();
    } catch (_) {
      context.go(user.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          await ref.read(customerAuthProvider.notifier).restoreSession();
      final user =
    try {
    }
      return;
      context.go('/login');
    if (token == null) {
    if (!mounted) return;
    final token = await ref.read(customerSessionProvider).readAccessToken();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  Future<void> _checkAuth() async {

  }
    Future.microtask(_checkAuth);
    super.initState();
  void initState() {
  @override
class _SplashScreenState extends ConsumerState<SplashScreen> {

}
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
  @override

  const SplashScreen({super.key});
class SplashScreen extends ConsumerStatefulWidget {

import '../widgets/customer_widgets.dart';
import '../../domain/customer_models.dart';
import '../../data/customer_repositories.dart';
import '../../application/customer_providers.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
}

