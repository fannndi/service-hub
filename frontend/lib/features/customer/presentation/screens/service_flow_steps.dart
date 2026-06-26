import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/customer_providers.dart';
import '../../domain/customer_models.dart';
import '../../../../shared_widgets/formatters.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../widgets/customer_widgets.dart';

// ─── Shared State ───

class FlowState {
  String? selectedBrand;
  String? selectedModel;
  String deviceType = 'android';
  String serviceType = 'screen_replacement';
  final complaint = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
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
          segments: const [
            ButtonSegment(
                value: 'android',
                label: Text('Android'),
                icon: Icon(Icons.android)),
            ButtonSegment(
                value: 'ios',
                label: Text('iPhone / iOS'),
                icon: Icon(Icons.phone_iphone)),
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
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
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
                    initialValue: brandValue,
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
                    initialValue: modelValue,
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
      return const Center(child: CircularProgressIndicator());
    }
    if (state.matchedStores.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l10n.partnerStoreRecommendation, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
              context.l10n.noMatchingStore,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text(
              context.l10n.checkSelectionSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(context.l10n.back)),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pilih Toko Mitra', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
            '${state.matchedStores.length} toko tersedia untuk perangkat kamu.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),

        // Selected sparepart indicator
        if (state.selectedPartId != null)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading:
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              title: Text(state.selectedPartName ?? 'Sparepart dipilih',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Harga: ${formatRupiah(state.selectedPartPrice)}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    state.selectedPartId = null;
                    state.selectedPartName = null;
                    state.selectedPartPrice = 0;
                  });
                },
              ),
            ),
          ),

        // Store cards
        ...state.matchedStores.map((store) {
          final selected = store.storeId == state.selectedStoreId;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: selected ? theme.colorScheme.primaryContainer : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: selected
                  ? BorderSide(color: theme.colorScheme.primary)
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onSelectStore(store),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(store.storeName,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold))),
                        Row(children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(store.ratingAvg.toStringAsFixed(1),
                              style: theme.textTheme.bodyMedium),
                        ]),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(store.address,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 8),
                      Text('${store.totalCompleted} servis selesai',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.tertiary)),

                      // Spareparts — tappable
                      if (store.spareparts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Sparepart Tersedia',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ...store.spareparts.map((sp) {
                          final isPartSelected = sp.id == state.selectedPartId;
                          return InkWell(
                            onTap: sp.status != 'available'
                                ? null
                                : () {
                                    setState(() {
                                      state.selectedPartId = sp.id;
                                      state.selectedPartName = sp.partName;
                                      state.selectedPartPrice = sp.price;
                                      // Set estimate cost to sparepart price
                                      state.estimateCost = sp.price;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: isPartSelected
                                    ? theme.colorScheme.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                Icon(
                                  isPartSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: isPartSelected
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(sp.partName,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  fontWeight: isPartSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal)),
                                      Text(
                                          sp.status == 'available'
                                              ? 'Tersedia'
                                              : 'Preorder',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: sp.status == 'available'
                                                  ? Colors.green
                                                  : Colors.orange)),
                                    ],
                                  ),
                                ),
                                Text(formatRupiah(sp.price),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          );
                        }),
                      ],

                      const Divider(height: 16),
                      Row(children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 4),
                        Text(
                            'Estimasi awal: ${formatRupiah(store.estimatedCost)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    ]),
              ),
            ),
          );
        }),
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
        Text('Data Diri & Pengiriman', style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'walk_in',
                label: Text('Antar ke Toko'),
                icon: Icon(Icons.store)),
            ButtonSegment(
                value: 'courier_pickup',
                label: Text('Pickup Kurir'),
                icon: Icon(Icons.local_shipping)),
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
          decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp',
              prefixText: '08',
              prefixIcon: Icon(Icons.phone_outlined)),
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
        Text('Konfirmasi Booking', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
              _ConfirmRow(label: 'WhatsApp', value: state.phone.text),
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
                Text('Estimasi Biaya',
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
