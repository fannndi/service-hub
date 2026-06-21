import 'package:flutter/material.dart';
import '../domain/address_models.dart';
import '../data/address_repository.dart';

class AddressDropdowns extends StatefulWidget {
  final bool enabled;

  const AddressDropdowns({super.key, this.enabled = true});

  @override
  State<AddressDropdowns> createState() => AddressDropdownsState();
}

class AddressDropdownsState extends State<AddressDropdowns> {
  final _detailController = TextEditingController();

  Province? _selectedProvince;
  City? _selectedCity;
  District? _selectedDistrict;
  Village? _selectedVillage;

  List<Province> _provinces = [];
  List<City> _cities = [];
  List<District> _districts = [];
  List<Village> _villages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await AddressRepository.init();
      setState(() {
        _provinces = AddressRepository.provinces;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onProvinceChanged(Province? p) {
    setState(() {
      _selectedProvince = p;
      _selectedCity = null;
      _selectedDistrict = null;
      _selectedVillage = null;
      _cities = p != null ? AddressRepository.citiesByProvince(p.id) : [];
      _districts = [];
      _villages = [];
    });
  }

  void _onCityChanged(City? c) {
    setState(() {
      _selectedCity = c;
      _selectedDistrict = null;
      _selectedVillage = null;
      _districts = c != null ? AddressRepository.districtsByCity(c.id) : [];
      _villages = [];
    });
  }

  void _onDistrictChanged(District? d) {
    setState(() {
      _selectedDistrict = d;
      _selectedVillage = null;
      _villages = d != null ? AddressRepository.villagesByDistrict(d.id) : [];
    });
  }

  void _onVillageChanged(Village? v) {
    setState(() => _selectedVillage = v);
  }

  String get addressString {
    if (_selectedProvince == null ||
        _selectedCity == null ||
        _selectedDistrict == null ||
        _selectedVillage == null) {
      return '';
    }
    return AddressRepository.formatAddress(
      detail: _detailController.text.trim(),
      villageName: _selectedVillage!.name,
      districtName: _selectedDistrict!.name,
      cityName: _selectedCity!.name,
      provinceName: _selectedProvince!.name,
    );
  }

  bool get isValid =>
      _selectedProvince != null &&
      _selectedCity != null &&
      _selectedDistrict != null &&
      _selectedVillage != null;

  void clear() {
    _detailController.clear();
    setState(() {
      _selectedProvince = null;
      _selectedCity = null;
      _selectedDistrict = null;
      _selectedVillage = null;
      _cities = [];
      _districts = [];
      _villages = [];
    });
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown<Province>(
          label: 'Provinsi',
          value: _selectedProvince,
          items: _provinces,
          itemLabel: (p) => p.name,
          onChanged: _onProvinceChanged,
        ),
        const SizedBox(height: 12),
        _buildDropdown<City>(
          label: 'Kota / Kabupaten',
          value: _selectedCity,
          items: _cities,
          itemLabel: (c) => c.name,
          onChanged: _selectedProvince != null ? _onCityChanged : null,
        ),
        const SizedBox(height: 12),
        _buildDropdown<District>(
          label: 'Kecamatan',
          value: _selectedDistrict,
          items: _districts,
          itemLabel: (d) => d.name,
          onChanged: _selectedCity != null ? _onDistrictChanged : null,
        ),
        const SizedBox(height: 12),
        _buildDropdown<Village>(
          label: 'Kelurahan / Desa',
          value: _selectedVillage,
          items: _villages,
          itemLabel: (v) => v.name,
          onChanged: _selectedDistrict != null ? _onVillageChanged : null,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _detailController,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            labelText: 'Detail Alamat',
            hintText: 'Nama jalan, RT/RW, nomor rumah, dll.',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
      ),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: widget.enabled ? onChanged : null,
    );
  }
}
