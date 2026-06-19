import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

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
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: parts
            .map((part) => ListTile(
                  enabled: part.availableQty > 0,
                  title: Text(part.partName),
                  subtitle: Text('${part.availableQty} tersedia'),
                  trailing: Text(rupiah(part.price)),
                  onTap: part.availableQty <= 0
                      ? null
                      : () => Navigator.pop(context, part),
                ))
            .toList(),
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
          extra: result.isNewCustomer);
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
      title: 'Buat Order',
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 32),
        child: FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: const Icon(Icons.check),
            label: Text(_loading
                ? 'Membuat order...'
                : 'Estimasi ${rupiah(_estimate)} - Buat Order')),
      ),
      child: Form(
        key: _form,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SectionTitle('Info Pelanggan'),
              TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Nomor HP', border: OutlineInputBorder()),
                  validator: _required),
              const SectionTitle('Info Perangkat'),
              SegmentedButton(
                  selected: {
                    _deviceType
                  },
                  segments: const [
                    ButtonSegment(value: 'android', label: Text('Android')),
                    ButtonSegment(value: 'ios', label: Text('iOS'))
                  ],
                  onSelectionChanged: (v) =>
                      setState(() => _deviceType = v.first)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _brand,
                  decoration: const InputDecoration(
                      labelText: 'Brand', border: OutlineInputBorder()),
                  validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _model,
                  decoration: const InputDecoration(
                      labelText: 'Model Device', border: OutlineInputBorder()),
                  validator: _required),
              const SectionTitle('Kerusakan'),
              DropdownButtonFormField(
                  initialValue: _serviceType,
                  decoration: const InputDecoration(
                      labelText: 'Jenis Servis', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'screen_replacement', child: Text('Layar')),
                    DropdownMenuItem(
                        value: 'battery_replacement', child: Text('Baterai')),
                    DropdownMenuItem(
                        value: 'charging_port', child: Text('Port')),
                    DropdownMenuItem(value: 'camera', child: Text('Kamera')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => setState(() => _serviceType = v!)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _complaint,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Deskripsi kerusakan',
                      border: OutlineInputBorder()),
                  validator: (v) => v == null || v.length < 10
                      ? 'Minimal 10 karakter.'
                      : null),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed:
                      spareparts.isEmpty ? null : () => _selectPart(spareparts),
                  icon: const Icon(Icons.inventory),
                  label: Text(_selectedPart?.partName ?? 'Pilih Sparepart')),
              const SectionTitle('Pengiriman'),
              SegmentedButton(
                  selected: {
                    _delivery
                  },
                  segments: const [
                    ButtonSegment(
                        value: 'walk_in', label: Text('Antar Sendiri')),
                    ButtonSegment(
                        value: 'courier_pickup', label: Text('Pickup Kurir'))
                  ],
                  onSelectionChanged: (v) =>
                      setState(() => _delivery = v.first)),
              if (_delivery == 'courier_pickup') ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                        labelText: 'Alamat Pickup',
                        border: OutlineInputBorder()),
                    validator: _required),
              ],
              const SizedBox(height: 12),
              TextFormField(
                  controller: _coupon,
                  decoration: const InputDecoration(
                      labelText: 'Kode Kupon (opsional)',
                      border: OutlineInputBorder())),
            ]),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
}
