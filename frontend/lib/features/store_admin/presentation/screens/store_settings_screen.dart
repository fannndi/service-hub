import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../application/profile_provider.dart';
import '../widgets/store_admin_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});
  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final storeName = TextEditingController();
  final address = TextEditingController();
  final phoneNumber = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    storeName.dispose();
    address.dispose();
    phoneNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(storeProfileProvider);
    final scheme = Theme.of(context).colorScheme; scheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.storeProfile), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/store/dashboard'))),
      body: profile.when(
        loading: () => const Center(child: M3LoadingIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (data) {
          if (!_initialized) {
            final store = data['store'] as Map<String, dynamic>? ?? {};
            storeName.text = store['storeName']?.toString() ?? '';
            address.text = store['address']?.toString() ?? '';
            phoneNumber.text = store['phoneNumber']?.toString() ?? '';
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: storeName,
                      decoration: InputDecoration(
                        labelText: context.l10n.storeName,
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: address,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: context.l10n.address,
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: phoneNumber,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: context.l10n.phoneNumber,
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : () async {
                          setState(() => _loading = true);
                          try {
                            await ref.read(storeProfileRepositoryProvider).updateProfile({
                              'storeName': storeName.text,
                              'address': address.text,
                              'phoneNumber': phoneNumber.text,
                            });
                            ref.invalidate(storeProfileProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.l10n.profileUpdated)));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.l10n.failed.replaceFirst('{error}', '$e'))));
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                        icon: _loading
                          ? SizedBox(width: 16, height: 16, child: M3LoadingIndicator(size: 20, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                        label: Text(context.l10n.saveChanges),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
