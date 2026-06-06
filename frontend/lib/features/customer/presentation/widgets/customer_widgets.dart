import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/customer_models.dart';

final rupiahFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final shortDateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
String rupiah(num value) => rupiahFormatter.format(value);
String shortDate(DateTime? value) =>
    value == null ? '-' : shortDateFormatter.format(value);

class CustomerScaffold extends StatelessWidget {
  const CustomerScaffold(
      {super.key,
      required this.title,
      required this.child,
      this.actions,
      this.floatingActionButton});
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: child,
        floatingActionButton: floatingActionButton,
      );
}

class AsyncPage<T> extends StatelessWidget {
  const AsyncPage({super.key, required this.value, required this.builder});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
        data: builder,
        loading: () => const SkeletonList(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              Text('Gagal memuat data',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.completed => Colors.green,
      OrderStatus.cancelled => Colors.red,
      OrderStatus.waitingPayment => Colors.orange,
      OrderStatus.waitingApproval => Colors.blue,
      OrderStatus.disputed => Colors.purple,
      _ => Colors.teal,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(status.label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  const StoreCard({super.key, required this.store, required this.onTap});
  final ServiceStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.storefront)),
          title: Text(store.storeName,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(store.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
                'Rating ${store.ratingAvg.toStringAsFixed(1)} (${store.reviewCount} ulasan)${store.verifiedAt != null ? '  - Verified' : ''}'),
          ]),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});
  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgent = order.slaDeadline != null &&
        order.slaDeadline!.difference(DateTime.now()).inHours < 6 &&
        order.status.isActive;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Row(children: [
          Expanded(
              child: Text(order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          StatusPill(order.status),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.storeName ?? 'Toko servis'),
            Text('${order.brand} ${order.deviceModel}'),
            Text(shortDate(order.createdAt),
                style: Theme.of(context).textTheme.bodySmall),
            if (urgent)
              Text('Batas waktu kurang dari 6 jam',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800))),
          if (action != null) action!,
        ]),
      );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ]),
        ),
      );
}

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.entries});
  final List<TrackingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const EmptyMessage('Tracking belum tersedia.');
    final sorted = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return ListTile(
          leading: Icon(
              index == 0 ? Icons.radio_button_checked : Icons.check_circle,
              color: index == 0
                  ? Theme.of(context).colorScheme.primary
                  : Colors.green),
          title: Text(entry.status.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
              '${entry.note ?? 'Status diperbarui.'}\n${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(entry.createdAt)}'),
        );
      },
    );
  }
}

class CouponRewardBanner extends StatelessWidget {
  const CouponRewardBanner({super.key, required this.coupon});
  final CouponReward coupon;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kupon diskon ${rupiah(coupon.amount)} sudah ditambahkan.',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SelectableText('Kode: ${coupon.code}'),
            Text('Berlaku s/d ${shortDate(coupon.expiredAt)}'),
          ]),
        ),
      );
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;
  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: count,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
              height: 84,
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12))),
        ),
      );
}
