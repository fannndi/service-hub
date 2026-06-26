import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../data/phone_utils.dart';
import '../../domain/customer_models.dart';
import '../../../../core/supabase_service.dart';
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
      final isGuest = SupabaseService.instance.user == null;
      final phone = normalizePhone(_state.phone.text.trim());
      final items = [
        {
          'service_type': _state.serviceType,
          'complaint': _state.complaint.text.trim(),
          if (_state.selectedPartId != null) 'sparepart_id': _state.selectedPartId,
          'item_price': _state.estimateCost,
        },
      ];

      final body = {
        'store_id': _state.selectedStoreId!,
        'device_type': _state.deviceType,
        'brand': _state.selectedBrand!,
        'device_model': _state.selectedModel!,
        'delivery_method': _state.delivery,
        if (_state.delivery == 'courier_pickup') 'delivery_address': _state.address.text.trim(),
        'customer_name': _state.name.text.trim(),
        'phone_number': phone,
        'items': items,
        if (_state.coupon.text.trim().isNotEmpty) 'coupon_code': _state.coupon.text.trim(),
      };

      if (isGuest) {
        final result = await SupabaseService.instance.invoke('guest', body: {'action': 'create-order', ...body});
        if (!mounted) return;
        final data = Map<String, dynamic>.from(result as Map? ?? {});
        context.go('/booking-success/${data['order_number']}', extra: data);
      } else {
        final result = await ref.read(orderRepositoryProvider).createOrder(
          CreateOrderRequest(
            storeId: _state.selectedStoreId!,
            fullName: _state.name.text.trim(),
            phoneNumber: phone,
            deviceType: _state.deviceType,
            brand: _state.selectedBrand!,
            deviceModel: _state.selectedModel!,
            deliveryMethod: _state.delivery,
            deliveryAddress: _state.delivery == 'courier_pickup' ? _state.address.text.trim() : null,
            couponCode: _state.coupon.text.trim().isEmpty ? null : _state.coupon.text.trim(),
            items: [CreateOrderItemInput(serviceType: _state.serviceType, complaint: _state.complaint.text.trim(), sparepartId: _state.selectedPartId, itemPrice: _state.estimateCost)],
          ),
        );
        if (!mounted) return;
        context.go('/booking-success/${result.orderNumber}', extra: result.isNewCustomer);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isApiError(error) ? parseApiError(error) : error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _state.loading = false);
    }
  }

  bool isApiError(Object error) => error.toString().contains('STOCK_UNAVAILABLE') || error.toString().contains('COUPON') || error.toString().contains('STORE_NOT_ACTIVE');

  void _nextStep() {
    if (_step >= 4) return;
    if (_step == 0 &&
        (_state.selectedBrand == null || _state.selectedModel == null)) {
      _showFlowMessage(context.l10n.selectBrandFirst);
      return;
    }
    if (_step == 1 && _state.complaint.text.trim().length < 10) {
      _showFlowMessage(context.l10n.complaintMinLength);
      return;
    }
    if (_step == 2 && _state.selectedStoreId == null) {
      _showFlowMessage(context.l10n.selectStoreFirst);
      return;
    }
    if (_step == 3 &&
        (_state.name.text.trim().isEmpty || _state.phone.text.trim().isEmpty)) {
      _showFlowMessage('Nama dan nomor WhatsApp wajib diisi.');
      return;
    }
    if (_step == 3 &&
        _state.delivery == 'courier_pickup' &&
        _state.address.text.trim().isEmpty) {
      _showFlowMessage('Alamat penjemputan wajib diisi untuk pickup kurir.');
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

  void _showFlowMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _prevStep() {
    if (_step <= 0) return;
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [context.l10n.device, context.l10n.damage, context.l10n.store, context.l10n.personalData, context.l10n.confirmation];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.serviceNow),
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
                  Step4Widget(state: _state, onChanged: () => setState(() {})),
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
                label: Text(context.l10n.back),
              )),
            if (_step > 0) const SizedBox(width: 12),
            if (_step < 4)
              Expanded(
                  child: FilledButton.icon(
                onPressed: _state.loading ? null : _nextStep,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_step == 0
                    ? context.l10n.findStore
                    : _step == 3
                        ? context.l10n.review
                        : context.l10n.continue_),
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
                label: Text(_state.loading ? context.l10n.processing : context.l10n.booking),
              )),
          ]),
        ),
      );
}
