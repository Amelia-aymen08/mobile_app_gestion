// Local residence photos placed in assets/residences/, keyed by a
// normalized residence name/id (lowercase, no accents, letters+digits only).
// To add a residence photo: drop the file in assets/residences/ and add a
// line below with its normalized key. No pubspec change needed — the whole
// assets/residences/ folder is already registered.
const Map<String, String> _residenceImageAssets = {
  'angelite': 'assets/residences/angelite.jpg',
  'corail': 'assets/residences/corail.jpg',
  'cornaline': 'assets/residences/cornaline.webp',
  'jais': 'assets/residences/jais.jpg',
  'peridot': 'assets/residences/peridot.jpg',
  'pyrite': 'assets/residences/pyrite.jpg',
  'selenite': 'assets/residences/selenite.jpg',
};

const Map<String, String> _accentReplacements = {
  'à': 'a', 'â': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i',
  'ô': 'o', 'ö': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

String _normalizeResidenceKey(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accentReplacements[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Returns the local asset path for a residence's photo, matching by id
/// first then by display name, or null if none is available locally.
String? residenceImageAsset({String? id, String? name}) {
  for (final candidate in [id, name]) {
    if (candidate == null || candidate.trim().isEmpty) continue;
    final asset = _residenceImageAssets[_normalizeResidenceKey(candidate)];
    if (asset != null) return asset;
  }
  return null;
}
