import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';

class GuestBookingSuccessScreen extends StatelessWidget {
  const GuestBookingSuccessScreen({
    super.key,
    required this.orderNumber,
  });

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bookingSuccess)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              context.l10n.orderCreated,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.saveOrderNumber,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(children: [
                  Text(context.l10n.orderNumber, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  SelectableText(orderNumber, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: orderNumber));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.orderNumberCopied)));
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(context.l10n.copy),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: scheme.primaryContainer.withAlpha(80),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.info_outline, color: scheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.guestInfoMessage,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/guest/track/$orderNumber'),
              icon: const Icon(Icons.search),
              label: Text(context.l10n.checkOrderStatus),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/welcome'),
              child: Text(context.l10n.backToHome),
            ),
          ],
        ),
      ),
    );
  }
}
