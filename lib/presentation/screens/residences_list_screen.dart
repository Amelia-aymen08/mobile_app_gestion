import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';

class ResidencesListScreen extends StatefulWidget {
  const ResidencesListScreen({super.key});

  @override
  State<ResidencesListScreen> createState() => _ResidencesListScreenState();
}

class _ResidencesListScreenState extends State<ResidencesListScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _api.getResidences();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résidences'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Text(
                        'Vos résidences (${_items.length})',
                        style: TextStyle(
                            color: muted, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ..._items.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ResidenceCard(data: r, dark: dark, muted: muted),
                          )),
                    ],
                  ),
                ),
    );
  }
}

class _ResidenceCard extends StatelessWidget {
  final dynamic data;
  final bool dark;
  final Color muted;
  const _ResidenceCard({required this.data, required this.dark, required this.muted});

  @override
  Widget build(BuildContext context) {
    if (data is! Map) return const SizedBox.shrink();
    final r = data as Map;
    final name = (r['name'] ?? '').toString();
    final zone = (r['zone'] ?? '').toString();
    final address = (r['address'] ?? '').toString();
    final image = (r['image'] ?? '').toString();
    final totalUnits = r['totalUnits'];
    final deliveredUnits = r['deliveredUnits'];
    final occupancy = (r['occupancyRate'] ?? '').toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dark ? darkBorder : const Color(0xFFE9E4D8)),
        ),
        child: Stack(
          children: [
            // ── Building image, right-aligned, faded into the card ──
            if (image.isNotEmpty)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.62,
                    heightFactor: 1,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          (dark ? darkCard : Colors.white),
                          (dark ? darkCard : Colors.white).withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.55],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (zone.isNotEmpty)
                    Text(zone.toUpperCase(),
                        style: TextStyle(
                            color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(name,
                      style: TextStyle(
                          color: dark ? Colors.white : brandNavy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: brandAmber),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(address,
                              style: TextStyle(color: muted, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (totalUnits != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (dark ? Colors.white : brandNavy).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _Stat(label: 'Unités', value: '$totalUnits', muted: muted, dark: dark),
                          if (deliveredUnits != null) ...[
                            _divider(dark),
                            _Stat(label: 'Livrées', value: '$deliveredUnits', muted: muted, dark: dark),
                          ],
                          if (occupancy.isNotEmpty) ...[
                            _divider(dark),
                            _Stat(label: 'Occupation', value: occupancy, muted: muted, dark: dark),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool dark) => Container(
        width: 1,
        height: 26,
        color: dark ? darkBorder : const Color(0xFFE2DDCF),
        margin: const EdgeInsets.symmetric(horizontal: 10),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color muted;
  final bool dark;
  const _Stat({required this.label, required this.value, required this.muted, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: dark ? Colors.white : brandNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
