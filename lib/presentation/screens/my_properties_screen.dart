// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/residence_images.dart';
import 'resident_create_ticket_screen.dart';
import 'property_add_request_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _properties = [];
  List<Map<String, dynamic>> _charges = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = context.read<AuthProvider>().user;
      final email = (user?['email'] ?? '').toString();
      if (email.isEmpty) {
        setState(() {
          _error = 'Utilisateur non identifié';
          _loading = false;
        });
        return;
      }
      final results = await Future.wait([
        _api.getMyProperties(email),
        _api.getMyCharges(),
      ]);
      if (!mounted) return;
      setState(() {
        _properties = results[0];
        _charges = results[1]
            .whereType<Map>()
            .map((c) => Map<String, dynamic>.from(c))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────
  String _aptNumber(dynamic lotNumber) {
    final raw = (lotNumber ?? '').toString().trim();
    if (raw.isEmpty) return '';
    final parts = raw.split('-').where((p) => p.trim().isNotEmpty).toList();
    return (parts.isNotEmpty ? parts.last : raw).trim();
  }

  String _typology(dynamic surface) {
    final s = double.tryParse((surface ?? '').toString());
    if (s == null) return 'F2';
    if (s >= 100) return 'F4';
    if (s >= 70) return 'F3';
    return 'F2';
  }

  String _residenceId(dynamic property) {
    if (property is! Map) return '';
    if (property['Residence'] is Map) {
      return (property['Residence']['id'] ?? '').toString();
    }
    return (property['residenceId'] ?? '').toString();
  }

  String _residenceName(dynamic property) {
    if (property is! Map) return '';
    if (property['Residence'] is Map) {
      return (property['Residence']['name'] ?? '').toString();
    }
    return '';
  }

  String? _propertyImage(Map property) {
    final residence =
        property['Residence'] is Map ? property['Residence'] as Map : const {};
    final raw = '${property['image'] ?? residence['image'] ?? ''}'.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    final base = _api.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/${raw.startsWith('/') ? raw.substring(1) : raw}';
  }

  // Returns charges associated with a property (matched by residenceId)
  List<Map<String, dynamic>> _chargesFor(dynamic property) {
    final resId = _residenceId(property);
    if (resId.isEmpty) return [];
    return _charges.where((c) {
      final cResId = (c['Residence'] is Map)
          ? (c['Residence']['id'] ?? '').toString()
          : (c['residenceId'] ?? '').toString();
      return cResId == resId;
    }).toList();
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Mes Biens',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC2CAD2), Color(0xFF8E9AA6)],
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.white70),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _fetchAll,
                            child: const Text('Réessayer')),
                      ],
                    ),
                  )
                : _properties.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.home_outlined,
                                    size: 36, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              const Text('Aucun bien associé à votre compte.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const PropertyAddRequestScreen())),
                                icon: const Icon(Icons.add_home_outlined),
                                label: const Text('Demander ajout de bien'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
                        itemCount: _properties.length,
                        itemBuilder: (_, i) => _propertyCard(_properties[i]),
                      ),
      ),
    );
  }

  Widget _propertyCard(dynamic property) {
    if (property is! Map) return const SizedBox.shrink();

    final aptNum = _aptNumber(property['lotNumber']);
    final title = aptNum.isNotEmpty
        ? 'Appartement n° $aptNum'
        : (property['title'] ?? 'Appartement').toString();
    final typology = (property['type'] ?? '').toString().trim().isNotEmpty
        ? property['type'].toString()
        : _typology(property['surface']);
    final floor = (property['floor'] ?? '').toString();
    final block = (property['block'] ?? '').toString();
    final residenceName = _residenceName(property);

    final charges = _chargesFor(property);
    final actives = charges.where((c) => (c['status'] ?? '') != 'Payé').length;
    final soldees = charges.where((c) => (c['status'] ?? '') == 'Payé').length;

    final localAsset = residenceImageAsset(id: _residenceId(property), name: residenceName);
    final imageUrl = _propertyImage(property);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image: local residence photo first, then network image, then placeholder
          SizedBox(
            height: 160,
            child: localAsset != null
                ? Image.asset(localAsset, fit: BoxFit.cover)
                : imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: brandBlue)),
                    ),
                    const SizedBox(width: 8),
                    _paymentBadge(actives, charges.length),
                  ],
                ),
                const SizedBox(height: 12),

                // Infos grid
                Row(
                  children: [
                    Expanded(child: _infoChip(Icons.bed_outlined, typology)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _infoChip(Icons.layers_outlined,
                            floor.isNotEmpty ? 'Étage $floor' : 'RDC')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _infoChip(Icons.grid_view_outlined,
                            block.isNotEmpty ? 'Bloc $block' : 'N/A')),
                  ],
                ),
                const SizedBox(height: 12),

                // Charges section
                if (charges.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: brandBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Charges',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (actives > 0) ...[
                              _chargeChip(
                                  '$actives active${actives > 1 ? 's' : ''}',
                                  const Color(0xFFDC2626),
                                  Icons.radio_button_unchecked),
                              const SizedBox(width: 8),
                            ],
                            if (soldees > 0)
                              _chargeChip(
                                  '$soldees soldée${soldees > 1 ? 's' : ''}',
                                  const Color(0xFF15803D),
                                  Icons.check_circle_outline),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (_charges.isNotEmpty) ...[
                  // Charges loaded but none for this property
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: Color(0xFF15803D)),
                      SizedBox(width: 6),
                      Text('Aucune charge en cours',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF15803D),
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Residence name at bottom
                if (residenceName.isNotEmpty) ...[
                  Row(children: [
                    const Icon(Icons.apartment_outlined,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(residenceName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],

                // Ticket button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResidentCreateTicketScreen(
                            property: Map<String, dynamic>.from(property),
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket envoyé.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.report_problem_outlined, size: 18),
                    label: const Text('Signaler un problème'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(Icons.apartment_outlined,
            size: 56, color: Color(0xFFCBD5E1)),
      );

  Widget _paymentBadge(int actives, int total) {
    final String label;
    final Color color;
    if (total == 0) {
      label = 'À jour';
      color = const Color(0xFF15803D);
    } else if (actives == 0) {
      label = 'À jour';
      color = const Color(0xFF15803D);
    } else {
      label = 'Impayé';
      color = const Color(0xFFDC2626);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: brandBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: brandBlue),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: brandBlue),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _chargeChip(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}
