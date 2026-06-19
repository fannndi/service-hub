import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      title: 'Keamanan',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Ganti Password'),
              subtitle: const Text('Perbarui password akun Anda'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/change-password'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: FutureBuilder<List<UserSession>>(
              future: ref.read(sessionRepositoryProvider).getSessions(),
              builder: (context, snapshot) {
                final active =
                    snapshot.data?.where((s) => s.isActive).length ?? 0;
                return ListTile(
                  leading: const Icon(Icons.devices),
                  title: const Text('Perangkat Aktif'),
                  subtitle: Text('$active perangkat terhubung'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/sessions'),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.phone),
              title: Text('Nomor HP'),
              subtitle: Text('Hubungi support untuk mengubah nomor HP'),
            ),
          ),
        ],
      ),
    );
  }
}
