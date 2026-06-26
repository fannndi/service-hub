import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../../../../core/l10n/app_localizations.dart';
import 'package:m3_expressive/m3_expressive.dart';

class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  final condition = TextEditingController();
  final damage = TextEditingController();
  final repair = TextEditingController();
  final technician = TextEditingController();
  final estimatedCost = TextEditingController();
  final estimatedDuration = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.diagnosisForm)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: condition,
              maxLines: 2,
              decoration:
                  InputDecoration(labelText: context.l10n.deviceCondition)),
          TextField(
              controller: damage,
              maxLines: 3,
              decoration:
                  InputDecoration(labelText: context.l10n.damageNotes)),
          TextField(
              controller: repair,
              maxLines: 3,
              decoration:
                  InputDecoration(labelText: context.l10n.repairNotes)),
          TextField(
              controller: technician,
              maxLines: 3,
              decoration:
                  InputDecoration(labelText: context.l10n.technicianNotes)),
          TextField(
              controller: estimatedCost,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: context.l10n.estimatedCost)),
          TextField(
              controller: estimatedDuration,
              decoration:
                  InputDecoration(labelText: context.l10n.estimatedDuration)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      await ref
                          .read(storeOrdersProvider.notifier)
                          .submitDiagnosis(widget.orderId, {
                        'deviceCondition': condition.text,
                        'damageNotes': damage.text,
                        'repairNotes': repair.text,
                        'technicianNotes': technician.text,
                        'estimatedCost': num.tryParse(estimatedCost.text) ?? 0,
                        'estimatedDuration': estimatedDuration.text,
                        'diagnosisItems': <Map<String, Object?>>[],
                        'serviceFee': num.tryParse(estimatedCost.text) ?? 0,
                      });
                      if (context.mounted) {
                        context.go('/store/orders/${widget.orderId}');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.failed
                                .replaceFirst('{error}', '$e'))));
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            icon: _loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: M3LoadingIndicator(size: 20, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: Text(context.l10n.submitDiagnosis),
          ),
        ]),
      );
}
