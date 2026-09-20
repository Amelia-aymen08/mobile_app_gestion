import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../l10n/l10n.dart';
import '../theme/amenities.dart';
import '../theme/app_theme.dart';
import '../theme/residence_images.dart';

/// "Ma résidence": short description and amenities (commodités) of the
/// resident's residence, taken from the Aymen Promotion Immobilière website.
class ResidenceDetailsScreen extends StatefulWidget {
  final String residenceId;

  /// What the caller already knows (name, address...), shown while loading.
  final Map<String, dynamic>? initial;

  const ResidenceDetailsScreen(
      {super.key, required this.residenceId, this.initial});

  @override
  State<ResidenceDetailsScreen> createState() => _ResidenceDetailsScreenState();
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _residence;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _residence = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.getResidence(widget.residenceId);
      if (mounted) setState(() => _residence = r);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final r = _residence ?? const <String, dynamic>{};

    final name = (r['name'] ?? '').toString();
    final address = (r['address'] ?? '').toString();
    final description = (r['description'] ?? '').toString().trim();
    final amenities = (r['amenities'] is List)
        ? (r['amenities'] as List)
            .map((a) => a.toString().trim())
            .where((a) => a.isNotEmpty)
            .toList()
        : <String>[];
    final localAsset = residenceImageAsset(
        id: (r['id'] ?? widget.residenceId).toString(), name: name);
    final networkImage = _api.mediaUrl(r['image']);

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: dark ? darkSurface : brandNavy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(name.isNotEmpty ? name : 'Ma résidence'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              background: Stack(fit: StackFit.expand, children: [
                if (localAsset != null)
                  Image.asset(localAsset, fit: BoxFit.cover)
                else if (networkImage != null)
                  Image.network(networkImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: brandNavy))
                else
                  Container(color: brandNavy),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xAA000000)],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (address.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: brandAmber),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(address,
                            style: TextStyle(color: muted, fontSize: 14))),
                  ]),
                const SizedBox(height: 18),
                if (_loading && description.isEmpty && amenities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && description.isEmpty && amenities.isEmpty)
                  _emptyState(Icons.cloud_off_rounded, _error!.tr, muted)
                else ...[
                  _sectionTitle('À propos'.tr, fg),
                  const SizedBox(height: 10),
                  if (description.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: dark ? darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18)),
                      child: Text(description,
                          style: TextStyle(color: fg, fontSize: 14, height: 1.55)),
                    )
                  else
                    _emptyState(Icons.info_outline_rounded,
                        'Description bientôt disponible.'.tr, muted),
                  const SizedBox(height: 24),
                  _sectionTitle('Commodités'.tr, fg),
                  const SizedBox(height: 10),
                  if (amenities.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final key in amenities) _amenityChip(key, dark, fg),
                      ],
                    )
                  else
                    _emptyState(Icons.apartment_outlined,
                        'Les commodités seront bientôt renseignées.'.tr, muted),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, Color fg) => Text(text,
      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16));

  Widget _emptyState(IconData icon, String text, Color muted) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(icon, color: muted, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: muted, fontSize: 13))),
        ]),
      );

  Widget _amenityChip(String key, bool dark, Color fg) {
    final info = kAmenities[key];
    final label = info != null ? info.labelFr.tr : key;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandAmber.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(info?.icon ?? Icons.check_circle_outline_rounded,
            size: 18, color: brandAmber),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}
