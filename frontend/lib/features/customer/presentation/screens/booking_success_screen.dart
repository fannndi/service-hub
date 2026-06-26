import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/customer_widgets.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen(
      {super.key, required this.orderNumber, required this.isNewCustomer});
  final String orderNumber;
  final bool isNewCustomer;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: context.l10n.orderSuccess,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.check_circle, size: 84, color: Colors.green),
          const SizedBox(height: 16),
          Text(context.l10n.orderCreated,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SelectableText(orderNumber, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(context.l10n.adminConfirmMessage,
              textAlign: TextAlign.center),
          if (isNewCustomer)
            Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: ModernCard(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(context.l10n.whatsappInfoMessage))),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => context.go('/orders'),
              child: Text(context.l10n.viewMyOrders)),
          OutlinedButton(
              onPressed: () => context.go('/home'),
              child: Text(context.l10n.backToHome)),
        ]),
      );
}
