import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../ui/theme/app_decorations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../../../ui/widgets/shimmer_widget.dart';
import '../../domain/customer_models.dart';

final rupiahFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final shortDateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
String rupiah(num value) => rupiahFormatter.format(value);
String shortDate(DateTime? value) =>
    value == null ? '-' : shortDateFormatter.format(value);

class CustomerScaffold extends StatelessWidget {
  const CustomerScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: showBackButton
            ? Builder(
                builder: (ctx) {
                  if (Navigator.of(ctx).canPop()) {
                    return IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              )
            : null,
        leadingWidth: showBackButton ? 56 : null,
      ),
      body: GradientBackground(child: child),
      floatingActionButton: floatingActionButton,
    );
  }
}

class AsyncPage<T> extends StatelessWidget {
  const AsyncPage({super.key, required this.value, required this.builder});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
        data: builder,
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ShimmerWidget(count: 3),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gagal memuat data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
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
      OrderStatus.completed => const Color(0xFF10B981),
      OrderStatus.cancelled => const Color(0xFFEF4444),
      OrderStatus.waitingPayment => const Color(0xFFF59E0B),
      OrderStatus.waitingApproval => const Color(0xFF3B82F6),
      OrderStatus.disputed => const Color(0xFF8B5CF6),
      _ => const Color(0xFF06B6D4),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  const StoreCard({super.key, required this.store, required this.onTap});
  final ServiceStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: ModernCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: AppDecorations.iconBadge(
                scheme.primaryContainer.withValues(alpha: 0.8),
                size: 48,
              ),
              child: Icon(Icons.storefront_rounded, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${store.ratingAvg.toStringAsFixed(1)} (${store.reviewCount})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (store.verifiedAt != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified_rounded,
                            size: 14, color: scheme.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});
  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final urgent = order.slaDeadline != null &&
        order.slaDeadline!.difference(DateTime.now()).inHours < 6 &&
        order.status.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: ModernCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                StatusPill(order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.storeName ?? 'Toko servis',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('${order.brand} ${order.deviceModel}'),
            const SizedBox(height: 4),
            Text(
              shortDate(order.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            if (urgent) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: scheme.error),
                    const SizedBox(width: 4),
                    Text(
                      'Batas waktu kurang dari 6 jam',
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 32,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.entries});
  final List<TrackingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const EmptyMessage('Tracking belum tersedia.');
    final sorted = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        final isActive = index == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? scheme.primaryContainer
                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive
                          ? Icons.radio_button_checked_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                      color: isActive
                          ? scheme.primary
                          : const Color(0xFF10B981),
                    ),
                  ),
                  if (index < sorted.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: scheme.outlineVariant,
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.status.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        entry.note ?? 'Status diperbarui.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                            .format(entry.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CouponRewardBanner extends StatelessWidget {
  const CouponRewardBanner({super.key, required this.coupon});
  final CouponReward coupon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ModernCard(
        gradient: AppGradients.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kupon diskon ${rupiah(coupon.amount)} sudah ditambahkan.',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              'Kode: ${coupon.code}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Berlaku s/d ${shortDate(coupon.expiredAt)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: ShimmerWidget(count: count),
      );
}
