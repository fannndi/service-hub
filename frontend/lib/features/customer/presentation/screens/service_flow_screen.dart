import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import 'service_flow_steps.dart';

class ServiceFlowScreen extends ConsumerStatefulWidget {
  const ServiceFlowScreen({super.key});
  @override
  ConsumerState<ServiceFlowScreen> createState() => _ServiceFlowScreenState();
}

class _ServiceFlowScreenState extends ConsumerState<ServiceFlowScreen> {
  final _state = FlowState();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final user = ref.read(customerAuthProvider).valueOrNull;
    if (user != null) {
      _state.name.text = user.fullName;
      _state.phone.text = user.phoneNumber;
      _state.address.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _matchStores() async {
    if (_state.selectedBrand == null || _state.selectedModel == null) return;
    setState(() => _state.loading = true);
    try {
      final repo = ref.read(storeDiscoveryRepositoryProvider);
      _state.matchedStores = await repo.matchStores(
        brand: _state.selectedBrand!,
        deviceModel: _state.selectedModel!,
        partType: _state.serviceType,
      );
    } catch (_) {
      _state.matchedStores = const [];
    } finally {
      if (mounted) setState(() => _state.loading = false);
    }
  }

  void _selectStore(StoreMatchResult store) {
    setState(() {
      _state.selectedStoreId = store.storeId;
      _state.estimateCost = store.estimatedCost;
    });
  }

  Future<void> _createBooking() async {
    setState(() => _state.loading = true);
    try {
      final req = CreateOrderRequest(
        storeId: _state.selectedStoreId!,
        fullName: _state.name.text.trim(),
        phoneNumber: normalizePhone(_state.phone.text.trim()),
        deviceType: _state.deviceType,
        brand: _state.selectedBrand!,
        deviceModel: _state.selectedModel!,
        deliveryMethod: _state.delivery,
        deliveryAddress: _state.delivery == 'courier_pickup'
            ? _state.address.text.trim()
            : null,
        couponCode: _state.coupon.text.trim().isEmpty
            ? null
            : _state.coupon.text.trim(),
        items: [
          CreateOrderItemInput(
            serviceType: _state.serviceType,
            complaint: _state.complaint.text.trim(),
            sparepartId: _state.selectedPartId,
            itemPrice: _state.estimateCost,
          ),
        ],
      );
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      if (!mounted) return;
      context.go('/booking-success/${result.orderNumber}',
          extra: result.isNewCustomer);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parseApiError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _state.loading = false);
    }
  }

  void _nextStep() {
    if (_step >= 4) return;
    if (_step == 0 &&
        (_state.selectedBrand == null || _state.selectedModel == null)) {
      return;
    }
    if (_step == 1 && _state.complaint.text.isEmpty) return;
    if (_step == 2 && _state.selectedStoreId == null) return;
    if (_step == 3 && (_state.name.text.isEmpty || _state.phone.text.isEmpty)) {
      return;
    }

    if (_step == 1) {
      setState(() => _state.loading = true);
      _matchStores().then((_) {
        if (mounted) setState(() => _step = 2);
      });
      return;
    }

    setState(() => _step += 1);
  }

  void _prevStep() {
    if (_step <= 0) return;
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Perangkat', 'Kerusakan', 'Toko', 'Data Diri', 'Konfirmasi'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Now'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(steps.length, (i) {
                  final active = i == _step;
                  final done = i < _step;
                  return Expanded(
                    child: Column(children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? theme.colorScheme.primary
                              : active
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: active
                                          ? Colors.white
                                          : theme
                                              .colorScheme.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(steps[i],
                          style: TextStyle(
                              fontSize: 10,
                              color: active || done
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center),
                    ]),
                  );
                }),
              ),
            ),
            const Divider(),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [
                  Step1Widget(state: _state, onChanged: () => setState(() {})),
                  Step2Widget(state: _state, onChanged: () => setState(() {})),
                  Step3Widget(
                    state: _state,
                    onSelectStore: _selectStore,
                    onSelectPart: (id, name, price) {
                      setState(() {
                        _state.selectedPartId = id;
                        _state.selectedPartName = name;
                        _state.selectedPartPrice = price;
                        _state.estimateCost = price;
                      });
                    },
                    onBack: _prevStep,
                  ),
                  Step4Widget(state: _state),
                  Step5Widget(state: _state),
                ],
              ),
            ),
            _buildBottomNav(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (_step > 0)
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: _state.loading ? null : _prevStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              )),
            if (_step > 0) const SizedBox(width: 12),
            if (_step < 4)
              Expanded(
                  child: FilledButton.icon(
                onPressed: _state.loading ? null : _nextStep,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_step == 0
                    ? 'Cari Toko'
                    : _step == 3
                        ? 'Review'
                        : 'Lanjut'),
              ))
            else
              Expanded(
                  child: FilledButton.icon(
                onPressed: _state.loading ? null : _createBooking,
                icon: _state.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_state.loading ? 'Memproses...' : 'Booking'),
              )),
          ]),
        ),
      );
}
