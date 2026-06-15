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

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, this.item});
  final NotificationItem? item;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
      title: 'Detail Notifikasi',
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: item == null
              ? const EmptyMessage('Notifikasi tidak ditemukan.')
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item!.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(item!.message)
                ])));
}
