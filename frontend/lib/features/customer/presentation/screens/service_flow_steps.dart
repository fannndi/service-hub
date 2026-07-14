import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/customer_providers.dart';
import '../../domain/customer_models.dart';
import '../../../../shared_widgets/formatters.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../widgets/customer_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';

// ─── Shared State ───

class FlowState {
  String? selectedBrand;
  String? selectedModel;
  String deviceType = 'android';
  String serviceType = 'screen_replacement';
  final complaint = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final coupon = TextEditingController();
  String delivery = 'walk_in';
  String? selectedStoreId;
  String? selectedPartId;
  String? selectedPartName;
  double selectedPartPrice = 0;
  double estimateCost = 0;
  bool loading = false;
  List<StoreMatchResult> matchedStores = const [];

  void dispose() {
    complaint.dispose();
    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    coupon.dispose();
  }
}

// ─── Step 1: Device + Brand/Model ───

class Step1Widget extends ConsumerWidget {
  const Step1Widget({
    super.key,
    required this.state,
    required this.onChanged,
  });

  final FlowState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deviceModels = ref.watch(deviceModelsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.selectDevice, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(context.l10n.selectDeviceSubtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'android',
                label: Text(context.l10n.android),
                icon: const Icon(Icons.android)),
            ButtonSegment(
                value: 'ios',
                label: Text(context.l10n.iphoneIos),
                icon: const Icon(Icons.phone_iphone)),
          ],
          selected: {state.deviceType},
          onSelectionChanged: (v) {
            state.deviceType = v.first;
            onChanged();
          },
          showSelectedIcon: false,
        ),
        const SizedBox(height: 24),
        deviceModels.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: M3LoadingIndicator())),
          error: (error, _) => Text(context.l10n.deviceListLoadError.replaceFirst('{error}', error.toString()),
              style: TextStyle(color: theme.colorScheme.error)),
          data: (groups) {
            if (groups.isEmpty) {
              return EmptyMessage(context.l10n.noSparepartAvailable);
            }

            final brands = groups.map((g) => g.brand).toSet().toList()..sort();
            final selectedGroups =
                groups.where((g) => g.brand == state.selectedBrand).toList();
            final models = selectedGroups.isEmpty
                ? const <String>[]
                : (selectedGroups.first.models.toSet().toList()..sort());
            final brandValue = brands.contains(state.selectedBrand)
                ? state.selectedBrand
                : null;
            final modelValue = models.contains(state.selectedModel)
                ? state.selectedModel
                : null;

            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: brandValue,
                    decoration: InputDecoration(
                        labelText: context.l10n.smartphoneBrand,
                        prefixIcon: const Icon(Icons.branding_watermark)),
                    items: brands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) {
                      state.selectedBrand = v;
                      state.selectedModel = null;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: modelValue,
                    decoration: InputDecoration(
                        labelText: context.l10n.smartphoneType,
                        prefixIcon: const Icon(Icons.smartphone)),
                    items: models
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: state.selectedBrand == null
                        ? null
                        : (v) {
                            state.selectedModel = v;
                            onChanged();
                          },
                  ),
                ]);
          },
        ),
      ],
    );
  }
}

// ─── Step 2: Service Type + Complaint ───

class Step2Widget extends StatelessWidget {
  const Step2Widget({super.key, required this.state, required this.onChanged});

  final FlowState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = {
      'screen_replacement': context.l10n.screenReplacement,
      'battery_replacement': context.l10n.batteryReplacement,
      'charging_port': context.l10n.chargingPort,
      'camera': context.l10n.camera,
      'other': context.l10n.other,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.damageType, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(context.l10n.selectServiceTypeSubtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.entries
              .map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: state.serviceType == e.key,
                    onSelected: (v) {
                      if (v) {
                        state.serviceType = e.key;
                        onChanged();
                      }
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: state.complaint,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.complaintLabel,
            hintText: context.l10n.complaintHint,
            prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 64),
                child: Icon(Icons.report_problem_outlined)),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

// ─── Step 3: Store Selection + Sparepart Picker ───

class Step3Widget extends StatefulWidget {
  const Step3Widget({
    super.key,
    required this.state,
    required this.onSelectStore,
    required this.onSelectPart,
    required this.onBack,
  });

  final FlowState state;
  final void Function(StoreMatchResult) onSelectStore;
  final void Function(String partId, String partName, double price)
      onSelectPart;
  final VoidCallback onBack;

  @override
  State<Step3Widget> createState() => _Step3WidgetState();
}

class _Step3WidgetState extends State<Step3Widget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;

    if (state.loading && state.matchedStores.isEmpty) {
      return const Center(child: M3LoadingIndicator());
    }
    if (state.matchedStores.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l10n.partnerStoreRecommendation, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(context.l10n.noMatchingStore, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text(context.l10n.checkSelectionSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back), label: Text(context.l10n.back)),
        ],
      );
    }

    final selectedStore = state.matchedStores.where((s) => s.storeId == state.selectedStoreId).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.selectPartnerStore, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(context.l10n.storesAvailableCount.replaceFirst('{count}', state.matchedStores.length.toString()),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),

        // Store list — radio style
        ...state.matchedStores.map((store) {
          final selected = store.storeId == state.selectedStoreId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ModernCard(
              color: selected ? theme.colorScheme.primaryContainer : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () => widget.onSelectStore(store),
              child: Row(children: [
                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selected ? theme.colorScheme.primary : Colors.grey, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.storeName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  Row(children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(store.ratingAvg.toStringAsFixed(1), style: theme.textTheme.bodySmall),
                  ]),
                  const SizedBox(width: 8),
                  Text(context.l10n.completedServicesCount.replaceFirst('{count}', store.totalCompleted.toString()),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary)),
                ]),
            ),
          );
        }),

        // Sparepart section — only show if store selected
        if (selectedStore != null && selectedStore.spareparts.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(context.l10n.availableSparepart, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...selectedStore.spareparts.map((sp) {
            final isPartSelected = sp.id == state.selectedPartId;
return Padding(
             padding: const EdgeInsets.only(bottom: 8),
             child: ModernCard(
               color: isPartSelected ? theme.colorScheme.primaryContainer : null,
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               onTap: sp.status != 'available' ? null : () => setState(() {
                   widget.onSelectStore(selectedStore);
                   state.selectedPartId = sp.id;
                   state.selectedPartName = sp.partName;
                   state.selectedPartPrice = sp.price;
                   state.estimateCost = sp.price;
                 }),
               child: Row(children: [
                   Icon(isPartSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                       size: 20, color: isPartSelected ? theme.colorScheme.primary : Colors.grey),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                       Text(sp.partName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isPartSelected ? FontWeight.w600 : FontWeight.normal)),
                       Text(sp.status == 'available' ? context.l10n.available : context.l10n.preorder,
                           style: TextStyle(fontSize: 11, color: sp.status == 'available' ? Colors.green : Colors.orange)),
                     ]),
                   ),
                   Text(formatRupiah(sp.price), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                 ]),
             ),
           );
          }),
        ],

        // Selected part indicator
          if (state.selectedPartId != null) ...[
            const SizedBox(height: 16),
            ModernCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green.shade50,
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('${state.selectedPartName} - ${formatRupiah(state.selectedPartPrice)}',
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    state.selectedPartId = null;
                    state.selectedPartName = null;
                    state.selectedPartPrice = 0;
                  }),
                ),
              ]),
            ),
          ],
      ],
    );
  }
}

// ─── Step 4: Customer Info ───

class Step4Widget extends StatelessWidget {
  const Step4Widget({super.key, required this.state, required this.onChanged});

  final FlowState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.personalDataAndDelivery, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'walk_in',
                label: Text(context.l10n.dropOffToStore),
                icon: const Icon(Icons.store)),
            ButtonSegment(
                value: 'courier_pickup',
                label: Text(context.l10n.courierPickup),
                icon: const Icon(Icons.local_shipping)),
          ],
          selected: {state.delivery},
          onSelectionChanged: (v) {
            state.delivery = v.first;
            onChanged();
          },
          showSelectedIcon: false,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: state.name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: state.phone,
          keyboardType: TextInputType.phone,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
              labelText: 'No. HP',
              prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: state.email,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined)),
        ),
        if (state.delivery == 'courier_pickup') ...[
          const SizedBox(height: 16),
          TextField(
            controller: state.address,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Alamat Penjemputan',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true),
          ),
        ],
      ],
    );
  }
}

// ─── Step 5: Confirmation ───

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ]),
    );
  }
}

class Step5Widget extends StatelessWidget {
  const Step5Widget({super.key, required this.state});

  final FlowState state;

  static const typeLabels = {
    'screen_replacement': 'Ganti Layar',
    'battery_replacement': 'Ganti Baterai',
    'charging_port': 'Port Charger',
    'camera': 'Kamera',
    'other': 'Lainnya',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.bookingConfirmation, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        ModernCard(
          padding: EdgeInsets.all(AppSpacing.md),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ConfirmRow(
                label: 'Perangkat',
                value:
                    '${state.deviceType.toUpperCase()} - ${state.selectedBrand ?? '-'} ${state.selectedModel ?? '-'}'),
            const Divider(),
            _ConfirmRow(
                label: 'Layanan', value: typeLabels[state.serviceType]!),
            if (state.selectedPartId != null) ...[
              const Divider(),
              _ConfirmRow(
                  label: 'Sparepart',
                  value:
                      '${state.selectedPartName ?? '-'} — ${formatRupiah(state.selectedPartPrice)}'),
            ],
            const Divider(),
            _ConfirmRow(label: 'Keluhan', value: state.complaint.text),
            const Divider(),
            _ConfirmRow(label: 'Nama', value: state.name.text),
            const Divider(),
            _ConfirmRow(label: 'Email', value: state.email.text),
            if (state.delivery == 'courier_pickup') ...[
              const Divider(),
              _ConfirmRow(label: 'Alamat', value: state.address.text),
            ],
            const Divider(),
            _ConfirmRow(
                label: 'Pengiriman',
                value: state.delivery == 'walk_in'
                    ? 'Antar ke Toko'
                    : 'Pickup Kurir'),
            const Divider(height: 24),
            Row(children: [
              Text(context.l10n.costEstimate,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(formatRupiah(state.estimateCost),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 4),
            Text(
                '* Estimasi bersifat sementara, dapat berubah setelah diagnosis teknisi.',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: state.coupon,
          decoration: const InputDecoration(
              labelText: 'Kode Kupon (opsional)',
              prefixIcon: Icon(Icons.local_offer_outlined),
              isDense: true),
        ),
      ],
    );
  }
}
