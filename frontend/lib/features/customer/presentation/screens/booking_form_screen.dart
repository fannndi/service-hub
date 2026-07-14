import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../data/phone_utils.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({super.key, required this.storeId});
  final String storeId;
  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _complaint = TextEditingController();
  final _coupon = TextEditingController();
  final _address = TextEditingController();
  String _deviceType = 'android';
  String _delivery = 'walk_in';
  String _serviceType = 'screen_replacement';
  SparePart? _selectedPart;
  bool _loading = false;

  double get _estimate => _selectedPart?.price ?? 0;

  @override
  void initState() {
    super.initState();
    final user = ref.read(customerAuthProvider).valueOrNull;
    if (user != null) {
      _name.text = user.fullName;
      _phone.text = user.phoneNumber;
      _address.text = user.address ?? '';
    }
  }

  Future<void> _selectPart(List<SparePart> parts) async {
    final part = await showModalBottomSheet<SparePart>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: Row(
                children: [
                  Text('Pilih Sparepart', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: parts.length,
                padding: EdgeInsets.all(AppSpacing.md),
                itemBuilder: (_, i) {
                  final p = parts[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ModernCard(
                      child: ListTile(
                        enabled: p.availableQty > 0,
                        title: Text(p.partName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${p.availableQty} tersedia'),
                        trailing: Text(rupiah(p.price), style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                        onTap: p.availableQty <= 0 ? null : () => Navigator.pop(context, p),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (part != null) setState(() => _selectedPart = part);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final req = CreateOrderRequest(
        storeId: widget.storeId,
        fullName: _name.text,
        phoneNumber: normalizePhone(_phone.text),
        deviceType: _deviceType,
        brand: _brand.text,
        deviceModel: _model.text,
        deliveryMethod: _delivery,
        deliveryAddress: _delivery == 'courier_pickup' ? _address.text : null,
        couponCode: _coupon.text,
        items: [
          CreateOrderItemInput(
              serviceType: _serviceType,
              complaint: _complaint.text,
              sparepartId: _selectedPart?.id,
              itemPrice: _estimate)
        ],
      );
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      if (!mounted) return;
      context.go('/booking-success/${result.orderNumber}',
          extra: {'isNewCustomer': result.isNewCustomer});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spareparts =
        ref.watch(sparepartsProvider(widget.storeId)).valueOrNull ??
            const <SparePart>[];
    return CustomerScaffold(
      title: context.l10n.createOrder,
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 32),
        child: FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: const Icon(Icons.check),
            label: Text(_loading
                ? context.l10n.processing
                : '${context.l10n.costEstimate} ${rupiah(_estimate)} - ${context.l10n.createOrder}')),
      ),
      child: Form(
        key: _form,
child: ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 110),
            children: [
              SectionTitle(context.l10n.customerInfo),
              TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                      labelText: context.l10n.fullName),
                  validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: context.l10n.phoneNumber),
                  validator: _required),
              SectionTitle(context.l10n.deviceInfo),
              SegmentedButton(
                  selected: {
                    _deviceType
                  },
                  segments: [
                    ButtonSegment(value: 'android', label: Text(context.l10n.android)),
                    ButtonSegment(value: 'ios', label: Text(context.l10n.iphoneIos))
                  ],
                  onSelectionChanged: (v) =>
                      setState(() => _deviceType = v.first)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _brand,
                  decoration: InputDecoration(
                      labelText: context.l10n.smartphoneBrand,
                      prefixIcon: const Icon(Icons.branding_watermark_outlined)),
                  validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _model,
                  decoration: InputDecoration(
                      labelText: context.l10n.deviceModel,
                      prefixIcon: const Icon(Icons.phone_android_outlined)),
                  validator: _required),
              SectionTitle(context.l10n.damage),
              DropdownButtonFormField<String>(
                  value: _serviceType,
                  decoration: InputDecoration(
                      labelText: context.l10n.serviceType,
                      prefixIcon: const Icon(Icons.build_outlined)),
                  items: [
                    DropdownMenuItem(
                        value: 'screen_replacement', child: Text(context.l10n.screenReplacement)),
                    DropdownMenuItem(
                        value: 'battery_replacement', child: Text(context.l10n.batteryReplacement)),
                    DropdownMenuItem(
                        value: 'charging_port', child: Text(context.l10n.chargingPort)),
                    DropdownMenuItem(value: 'camera', child: Text(context.l10n.camera)),
                    DropdownMenuItem(value: 'other', child: Text(context.l10n.other)),
                  ],
                  onChanged: (v) => setState(() => _serviceType = v!),
                  borderRadius: const BorderRadius.all(Radius.circular(14))),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _complaint,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                      labelText: context.l10n.damageDescription,
                      border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.length < 10
                      ? context.l10n.minLength10
                      : null),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed:
                      spareparts.isEmpty ? null : () => _selectPart(spareparts),
                  icon: const Icon(Icons.inventory),
                  label: Text(_selectedPart?.partName ?? context.l10n.selectSparepart)),
              SectionTitle(context.l10n.delivery),
              SegmentedButton(
                  selected: {
                    _delivery
                  },
                  segments: [
                    ButtonSegment(
                        value: 'walk_in', label: Text(context.l10n.dropOffSelf)),
                    ButtonSegment(
                        value: 'courier_pickup', label: Text(context.l10n.courierPickup))
                  ],
                  onSelectionChanged: (v) =>
                      setState(() => _delivery = v.first)),
              if (_delivery == 'courier_pickup') ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: _address,
                    decoration: InputDecoration(
                        labelText: context.l10n.pickupAddress,
                        border: const OutlineInputBorder()),
                    validator: _required),
              ],
              const SizedBox(height: 12),
              TextFormField(
                  controller: _coupon,
                  decoration: InputDecoration(
                      labelText: context.l10n.couponCodeOptional,
                      border: const OutlineInputBorder())),
            ]),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? context.l10n.required : null;
}
