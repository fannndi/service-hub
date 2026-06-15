import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../../domain/user_session.dart';
import '../../../../shared_widgets/error_state.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../../../shared_widgets/empty_state.dart';
import '../../../../shared_widgets/formatters.dart';
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
                final active = snapshot.data?.where((s) => s.isActive).length ?? 0;
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
            child: const ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Nomor HP'),
              subtitle: const Text('Hubungi support untuk mengubah nomor HP'),
            ),
          ),
        ],
      ),
    );
  }
}
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...rows.entries.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 94, child: Text(row.key)),
                      Expanded(
                          child: Text(row.value,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)))
                    ]))),
          ]),
        ),
      );
}
