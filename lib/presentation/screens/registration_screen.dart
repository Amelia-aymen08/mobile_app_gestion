// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _apiService   = ApiService();
  bool _isLoading     = false;
  bool _isOptLoading  = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _blockCtrl     = TextEditingController();
  final _floorCtrl     = TextEditingController();
  final _doorCtrl      = TextEditingController();

  String? _selectedResidence;
  List<Map<String, dynamic>> _residences = [];
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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _blockCtrl.dispose();
    _floorCtrl.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchResidences() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getResidences();
      if (!mounted) return;
      setState(() {
        _residences = data
            .whereType<Map>()
            .map((r) => {
                  'id': (r['id'] ?? '').toString(),
                  'name': (r['name'] ?? '').toString(),
                })
            .where((r) => (r['id'] ?? '').toString().isNotEmpty)
            .cast<Map<String, dynamic>>()
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : {error}'.trp({'error': e}))));
      }
    }
  }

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

  Future<void> _fetchResidenceOptions(String residenceId) async {
    setState(() {
      _isOptLoading = true;
      _floors = [];
      _units = [];
      _selectedFloor = null;
      _selectedUnitId = null;
      _blockCtrl.text = '';
      _floorCtrl.text = '';
      _doorCtrl.text = '';
    });
    try {
      final decoded = await _apiService.getRegistrationOptions(residenceId);
      final data = decoded['data'];
      final floors = (data is Map && data['floors'] is List)
          ? data['floors'] as List
          : const [];
      final units = (data is Map && data['units'] is List)
          ? data['units'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _floors = _sortFloors(
            floors.map((e) => (e ?? '').toString()).toList());
        _units = units
            .whereType<Map>()
            .map((u) => u.cast<String, dynamic>())
            .toList();
        _isOptLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOptLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : {error}'.trp({'error': e}))));
    }
  }

  List<Map<String, dynamic>> get _unitsForFloor {
    if (_selectedFloor == null) return [];
    final floor = _selectedFloor!.trim();
    final list = _units
        .where((u) => (u['floor'] ?? '').toString().trim() == floor)
        .toList();
    list.sort((a, b) {
      final an = int.tryParse((a['apartmentNumber'] ?? '').toString());
      final bn = int.tryParse((b['apartmentNumber'] ?? '').toString());
      if (an != null && bn != null) return an.compareTo(bn);
      return (a['apartmentNumber'] ?? '')
          .toString()
          .compareTo((b['apartmentNumber'] ?? '').toString());
    });
    return list;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.register({
        'firstName':  _firstNameCtrl.text.trim(),
        'lastName':   _lastNameCtrl.text.trim(),
        'email':      _emailCtrl.text.trim().toLowerCase(),
        'phone':      _phoneCtrl.text.trim(),
        'residenceId': _selectedResidence,
        'block':      _blockCtrl.text.trim(),
        'floor':      _floorCtrl.text.trim(),
        'door':       _doorCtrl.text.trim(),
      });
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Demande envoyée'.tr),
            content: Text(
                'Votre demande d\'inscription a été reçue. Vous recevrez vos accès par email après validation.'.tr),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: Text('OK'.tr),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Erreur'.tr),
            content: SingleChildScrollView(
                child: Text(e.toString().replaceAll('Exception: ', '').tr)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Fermer'.tr))
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBg(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) => SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  24, 32, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 56),
                child: Column(
                  children: [
                    // Logo row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/global_immo_logo_light.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 14),
                        Text('GÉRANCE IMMO\nSERVICE'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 1.8,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // White card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back + title
                            Row(children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back_rounded,
                                    color: brandNavy, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Text('Inscription'.tr,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: brandNavy)),
                            ]),
                            const SizedBox(height: 22),

                            // Prénom / Nom
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameCtrl,
                                  textInputAction: TextInputAction.next,
                                  decoration:
                                      InputDecoration(hintText: 'Prénom'.tr),
                                  validator: (v) =>
                                      v?.isEmpty ?? true ? 'Requis' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameCtrl,
                                  textInputAction: TextInputAction.next,
                                  decoration:
                                      InputDecoration(hintText: 'Nom'.tr),
                                  validator: (v) =>
                                      v?.isEmpty ?? true ? 'Requis' : null,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  InputDecoration(hintText: 'E-mail...'.tr),
                              validator: (v) {
                                final val = (v ?? '').trim();
                                if (val.isEmpty) return 'Requis'.tr;
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(val)) {
                                  return 'Email invalide'.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                  hintText: 'Numéro de téléphone'.tr),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Requis' : null,
                            ),
                            const SizedBox(height: 14),

                            // Residence dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedResidence,
                              isExpanded: true,
                              decoration: InputDecoration(
                                  hintText: 'Résidence'.tr),
                              items: _residences
                                  .map((r) => DropdownMenuItem(
                                      value: r['id'] as String,
                                      child: Text(r['name'] as String)))
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _selectedResidence = v);
                                if (v != null && v.isNotEmpty) {
                                  _fetchResidenceOptions(v);
                                }
                              },
                              validator: (v) => v == null ? 'Requis' : null,
                              hint: _isLoading
                                  ? Text('Chargement...'.tr)
                                  : Text('Sélectionner une résidence'.tr),
                            ),
                            const SizedBox(height: 14),

                            // Floor dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedFloor,
                              isExpanded: true,
                              decoration: InputDecoration(hintText: 'Étage'.tr),
                              items: _floors
                                  .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f.isEmpty
                                          ? 'Rez-de-chaussée'.tr
                                          : 'Étage {floor}'.trp({'floor': f}))))
                                  .toList(),
                              onChanged: _isOptLoading
                                  ? null
                                  : (v) => setState(() {
                                        _selectedFloor = v;
                                        _selectedUnitId = null;
                                        _floorCtrl.text = v ?? '';
                                        _blockCtrl.text = '';
                                        _doorCtrl.text = '';
                                      }),
                              validator: (v) => v == null ? 'Requis' : null,
                              hint: _selectedResidence == null
                                  ? Text('Sélectionner une résidence d\'abord'.tr)
                                  : _isOptLoading
                                      ? Text('Chargement...'.tr)
                                      : Text('Sélectionner un étage'.tr),
                            ),
                            const SizedBox(height: 14),

                            // Apartment dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedUnitId,
                              isExpanded: true,
                              decoration:
                                  InputDecoration(hintText: 'Appartement'.tr),
                              items: _unitsForFloor.map((u) {
                                final id  = (u['id'] ?? '').toString();
                                final apt = (u['apartmentNumber'] ?? '').toString();
                                final blk = (u['block'] ?? '').toString();
                                final lbl = blk.isNotEmpty
                                    ? 'N° {apt} - Bloc {block}'.trp({'apt': apt, 'block': blk})
                                    : 'N° {apt}'.trp({'apt': apt});
                                return DropdownMenuItem(
                                    value: id, child: Text(lbl));
                              }).toList(),
                              onChanged: (_isOptLoading || _selectedFloor == null)
                                  ? null
                                  : (v) => setState(() {
                                        _selectedUnitId = v;
                                        final u = _unitsForFloor.firstWhere(
                                            (u) => (u['id'] ?? '').toString() == (v ?? ''),
                                            orElse: () => <String, dynamic>{});
                                        _blockCtrl.text = (u['block'] ?? '').toString();
                                        _floorCtrl.text = (u['floor'] ?? _selectedFloor ?? '').toString();
                                        _doorCtrl.text  = (u['apartmentNumber'] ?? '').toString();
                                      }),
                              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                              hint: _selectedFloor == null
                                  ? Text('Sélectionner un étage d\'abord'.tr)
                                  : _isOptLoading
                                      ? Text('Chargement...'.tr)
                                      : _unitsForFloor.isEmpty
                                          ? Text('Aucun appartement libre'.tr)
                                          : Text('Sélectionner un appartement'.tr),
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('S\'inscrire'.tr),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Vous avez déjà un compte, '.tr,
                                  style: const TextStyle(
                                      color: Color(0xFF4B5563), fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text('connectez-vous.'.tr,
                                    style: const TextStyle(
                                      color: brandAmber,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                      decorationColor: brandAmber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

