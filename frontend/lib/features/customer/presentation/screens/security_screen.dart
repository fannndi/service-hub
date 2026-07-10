import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/customer_providers.dart';
import '../../domain/user_session.dart';
import '../widgets/customer_widgets.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});
  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      title: context.l10n.security,
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          ModernCard(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: Text(context.l10n.changePassword),
              subtitle: Text(context.l10n.updatePasswordSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/change-password'),
            ),
          ),
          const SizedBox(height: 8),
          ModernCard(
            child: FutureBuilder<List<dynamic>>(
              future: ref.read(sessionRepositoryProvider).getSessions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: Icon(Icons.devices),
                    title: Text('Memuat...'),
                    subtitle: Text('Mengambil data sesi'),
                  );
                }
                final sessions = (snapshot.data ?? [])
                    .map((j) => UserSession.fromJson(j as Map<String, dynamic>))
                    .toList();
                final active = sessions.where((s) => s.isActive).length;
                return ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text(context.l10n.activeDevices),
                  subtitle: Text(context.l10n.devicesConnected.replaceFirst('{count}', active.toString())),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/sessions'),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ModernCard(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: Text(context.l10n.phoneNumber),
              subtitle: Text(context.l10n.contactSupportForPhone),
            ),
          ),
        ],
      ),
    );
  }
}
