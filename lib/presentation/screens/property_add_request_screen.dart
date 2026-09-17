import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../providers/auth_provider.dart';

class PropertyAddRequestScreen extends StatefulWidget {
  const PropertyAddRequestScreen({super.key});

  @override
  State<PropertyAddRequestScreen> createState() => _PropertyAddRequestScreenState();
}

class _PropertyAddRequestScreenState extends State<PropertyAddRequestScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _loadingResidences = true;
  bool _isOptionsLoading = false;
  bool _submitting = false;
  List<dynamic> _residences = [];
  String? _selectedResidenceId;

  List<String> _floors = [];
  List<Map<String, dynamic>> _units = [];
  String? _selectedFloor;
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _fetchResidences();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchResidences() async {
    setState(() => _loadingResidences = true);
    try {
      final list = await _api.getResidences(forPropertyRequest: true);
      if (!mounted) return;
      setState(() {
        _residences = list;
        _loadingResidences = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingResidences = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  String _residenceLabel(dynamic r) {
    if (r is! Map) return '';
    final name = (r['name'] ?? '').toString().trim();
    final zone = (r['zone'] ?? '').toString().trim();
    if (name.isEmpty) return (r['id'] ?? '').toString();
    return zone.isNotEmpty ? '$name ($zone)' : name;
  }

  String _residenceId(dynamic r) {
    if (r is! Map) return '';
    return (r['id'] ?? '').toString().trim();
  }

  // Sort floors numerically; empty floor (no floor data) goes last
  List<String> _sortFloors(List<String> floors) {
    final copy = [...floors];
    copy.sort((a, b) {
      if (a.isEmpty && b.isEmpty) return 0;
      if (a.isEmpty) return 1;
      if (b.isEmpty) return -1;
      final ai = int.tryParse(a.trim());
      final bi = int.tryParse(b.trim());
      if (ai != null && bi != null) return ai.compareTo(bi);
      return a.compareTo(b);
    });
    return copy;
  }

  String _floorLabel(String floor) => floor.isEmpty ? 'Rez-de-chaussée' : 'Étage $floor';

  Future<void> _fetchResidenceOptions(String residenceId) async {
    setState(() {
      _isOptionsLoading = true;
      _floors = [];
      _units = [];
      _selectedFloor = null;
      _selectedUnitId = null;
    });

    try {
      final decoded = await _api.getRegistrationOptions(residenceId);
      final data = decoded['data'];
      final floors = (data is Map && data['floors'] is List) ? (data['floors'] as List) : const [];
      final units = (data is Map && data['units'] is List) ? (data['units'] as List) : const [];

      if (!mounted) return;
      setState(() {
        _floors = _sortFloors(
          floors.map((e) => (e ?? '').toString()).toList(),
        );
        _units = units.whereType<Map>().map((u) => u.cast<String, dynamic>()).toList();
        _isOptionsLoading = false;
      });

      if (_floors.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun appartement libre disponible dans cette résidence.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOptionsLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  List<Map<String, dynamic>> get _availableUnitsForSelectedFloor {
    if (_selectedFloor == null) return [];
    final floor = _selectedFloor!.trim();
    final list = _units
        .where((u) => (u['floor'] ?? '').toString().trim() == floor)
        .toList();
    list.sort((a, b) {
      final an = int.tryParse((a['apartmentNumber'] ?? '').toString());
      final bn = int.tryParse((b['apartmentNumber'] ?? '').toString());
      if (an != null && bn != null) return an.compareTo(bn);
      return (a['apartmentNumber'] ?? '').toString().compareTo((b['apartmentNumber'] ?? '').toString());
    });
    return list;
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    if ((_selectedResidenceId ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une résidence.')));
      return;
    }
    if ((_selectedUnitId ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un appartement.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await _api.submitPropertyAddRequest(
        residenceId: _selectedResidenceId!,
        propertyId: _selectedUnitId!,
        notes: '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée avec succès.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final email = (user?['email'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Demander ajout de bien')),
      body: _loadingResidences
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 12),

                    // Résidence
                    DropdownButtonFormField<String>(
                      value: _selectedResidenceId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Résidence',
                        border: OutlineInputBorder(),
                      ),
                      items: _residences
                          .whereType<Map>()
                          .map((r) {
                            final id = _residenceId(r);
                            final label = _residenceLabel(r);
                            if (id.isEmpty) return null;
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(label.isNotEmpty ? label : id, overflow: TextOverflow.ellipsis),
                            );
                          })
                          .whereType<DropdownMenuItem<String>>()
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (v) {
                              setState(() {
                                _selectedResidenceId = v;
                                _selectedFloor = null;
                                _selectedUnitId = null;
                                _floors = [];
                                _units = [];
                              });
                              if (v != null && v.trim().isNotEmpty) _fetchResidenceOptions(v);
                            },
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),

                    // Étage
                    DropdownButtonFormField<String>(
                      value: _selectedFloor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Étage',
                        border: OutlineInputBorder(),
                      ),
                      hint: _selectedResidenceId == null
                          ? const Text('Sélectionner une résidence d\'abord')
                          : _isOptionsLoading
                              ? const Text('Chargement…')
                              : _floors.isEmpty
                                  ? const Text('Aucun étage disponible')
                                  : const Text('Sélectionner un étage'),
                      items: _floors
                          .map((f) => DropdownMenuItem<String>(
                                value: f,
                                child: Text(_floorLabel(f)),
                              ))
                          .toList(),
                      onChanged: _isOptionsLoading || _submitting
                          ? null
                          : (v) {
                              setState(() {
                                _selectedFloor = v;
                                _selectedUnitId = null;
                              });
                            },
                      // floor can be empty string (= Rez-de-chaussée), so only null is invalid
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),

                    // Appartement
                    DropdownButtonFormField<String>(
                      value: _selectedUnitId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Appartement',
                        border: OutlineInputBorder(),
                      ),
                      hint: _selectedFloor == null
                          ? const Text('Sélectionner un étage d\'abord')
                          : _isOptionsLoading
                              ? const Text('Chargement…')
                              : _availableUnitsForSelectedFloor.isEmpty
                                  ? const Text('Aucun appartement libre')
                                  : const Text('Sélectionner un appartement'),
                      items: _availableUnitsForSelectedFloor.map((u) {
                        final id = (u['id'] ?? '').toString();
                        final apt = (u['apartmentNumber'] ?? '').toString();
                        final block = (u['block'] ?? '').toString().trim();
                        final label = block.isNotEmpty ? 'N° $apt - Bloc $block' : 'N° $apt';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _isOptionsLoading || _submitting || _selectedFloor == null
                          ? null
                          : (v) => setState(() => _selectedUnitId = v),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Envoyer la demande'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
