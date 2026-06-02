import 'package:flutter/material.dart';

import '../shared_widgets/status_badge.dart';

class CredentialPanelCard extends StatelessWidget {
  const CredentialPanelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Credential Pelanggan Baru', style: TextStyle(fontWeight: FontWeight.w800)), StatusBadge(label: 'Belum dikirim')],
            ),
            const SizedBox(height: 8),
            const Text('HP: 081234567890'),
            const Text('Password awal: SG-2026-demo'),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.copy), label: const Text('Salin password')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () {}, child: const Text('Sudah dikirim')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
