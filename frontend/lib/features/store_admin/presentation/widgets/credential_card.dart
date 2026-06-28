import 'package:flutter/material.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../domain/store_admin_models.dart';
import 'admin_formatters.dart';

class CredentialCard extends StatelessWidget {
  const CredentialCard({super.key, required this.panel});
  final CredentialPanel panel;
  @override
  Widget build(BuildContext context) => ModernCard(
      padding: const EdgeInsets.all(16),
      color: panel.hasCredential
          ? Theme.of(context).colorScheme.tertiaryContainer
          : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              panel.hasCredential
                  ? 'Pelanggan Baru - Kirim via WA'
                  : 'Kredensial sudah terkirim atau expired',
              style: Theme.of(context).textTheme.titleMedium),
          Text('HP: ${panel.phoneNumber}'),
          if (panel.password != null) Text('Password: ${"*" * 8}'),
          if (panel.expiresAt != null)
            Text('Berlaku s/d: ${dateText(panel.expiresAt!)}'),
        ]),
    );
}
