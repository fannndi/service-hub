import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../../../../../core/l10n/app_localizations.dart';
import 'package:m3_expressive/m3_expressive.dart';

class SparepartFormScreen extends ConsumerStatefulWidget {
  const SparepartFormScreen({super.key, this.item});
  final Sparepart? item;
  @override
  ConsumerState<SparepartFormScreen> createState() =>
      _SparepartFormScreenState();
}

class _SparepartFormScreenState extends ConsumerState<SparepartFormScreen> {
  String? _selectedBrand;
  String? _selectedDeviceModel;
  String _selectedPartType = 'screen_replacement';
  late final _partName = TextEditingController(text: widget.item?.partName);
  late final _price =
      TextEditingController(text: widget.item?.price.toString());
  late final _qty = TextEditingController(text: widget.item?.qty.toString());
  final _newBrandController = TextEditingController();
  final _newModelController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.item?.brand;
    _selectedDeviceModel = widget.item?.deviceModel;
    if (widget.item != null) _selectedPartType = widget.item!.partType;
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider).valueOrNull;
    final deviceModels =
        ref.watch(deviceModelsProvider(_selectedBrand)).valueOrNull;

    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.item == null ? context.l10n.addSparepart : context.l10n.editSparepart)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildBrandField(brands ?? []),
        const SizedBox(height: 12),
        _buildModelField(deviceModels ?? []),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedPartType,
          decoration: InputDecoration(
              labelText: context.l10n.sparepartType,
              prefixIcon: const Icon(Icons.build_outlined)),
          items: [
            DropdownMenuItem(value: 'screen_replacement', child: Text(context.l10n.screen)),
            DropdownMenuItem(
                value: 'battery_replacement', child: Text(context.l10n.battery)),
            DropdownMenuItem(
                value: 'charging_port', child: Text(context.l10n.chargingPort)),
            DropdownMenuItem(value: 'camera', child: Text(context.l10n.camera)),
            DropdownMenuItem(value: 'other', child: Text(context.l10n.other)),
          ],
          onChanged: (v) => setState(() => _selectedPartType = v!),
        ),
        const SizedBox(height: 12),
        TextField(
            controller: _partName,
            decoration: InputDecoration(
                labelText: context.l10n.sparepartName,
                hintText: context.l10n.sparepartNameHint,
                border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: context.l10n.price,
                prefixText: 'Rp ',
                border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        if (widget.item == null)
          TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: context.l10n.initialStock)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: M3LoadingIndicator(size: 20, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: Text(widget.item == null ? context.l10n.add : context.l10n.save),
        ),
      ]),
    );
  }

  Widget _buildBrandField(List<String> brands) {
    final allBrands = [...brands];
    if (_selectedBrand != null && !allBrands.contains(_selectedBrand)) {
      allBrands.insert(0, _selectedBrand!);
    }
    return Row(children: [
      Expanded(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedBrand,
          decoration: InputDecoration(
              labelText: context.l10n.brand,
              prefixIcon: const Icon(Icons.branding_watermark_outlined)),
          items: allBrands
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedBrand = v;
            _selectedDeviceModel = null;
          }),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showAddDialog(context.l10n.brand, _newBrandController, (val) {
                setState(() => _selectedBrand = val);
                ref.invalidate(brandsProvider);
              })),
    ]);
  }

  Widget _buildModelField(List<String> models) {
    final allModels = [...models];
    if (_selectedDeviceModel != null &&
        !allModels.contains(_selectedDeviceModel)) {
      allModels.insert(0, _selectedDeviceModel!);
    }
    return Row(children: [
      Expanded(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedDeviceModel,
          decoration: InputDecoration(
              labelText: context.l10n.deviceModel,
              prefixIcon: const Icon(Icons.phone_android_outlined)),
          items: allModels
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _selectedDeviceModel = v),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _selectedBrand == null
              ? null
              : () =>
                  _showAddDialog(context.l10n.deviceModel, _newModelController, (val) {
                    setState(() => _selectedDeviceModel = val);
                    ref.invalidate(deviceModelsProvider(_selectedBrand));
                  })),
    ]);
  }

  void _showAddDialog(
      String title, TextEditingController controller, Function(String) onAdd) {
    controller.clear();
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                title: Text('${context.l10n.add} $title'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(hintText: '${context.l10n.name} $title')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(context.l10n.cancel)),
                  FilledButton(
                      onPressed: () {
                        final val = controller.text.trim();
                        if (val.isNotEmpty) {
                          onAdd(val);
                          Navigator.pop(c);
                        }
                      },
                      child: Text(context.l10n.add)),
                ]));
  }

  Future<void> _submit() async {
    if (_selectedBrand == null ||
        _selectedDeviceModel == null ||
        _partName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.sparepartValidation)));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(inventoryProvider.notifier).save({
        'brand': _selectedBrand!,
        'deviceModel': _selectedDeviceModel!,
        'partType': _selectedPartType,
        'partName': _partName.text,
        'price': num.tryParse(_price.text) ?? 0,
        'qty': int.tryParse(_qty.text) ?? 0,
      }, id: widget.item?.id);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.failed.replaceFirst('{error}', '$e'))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
