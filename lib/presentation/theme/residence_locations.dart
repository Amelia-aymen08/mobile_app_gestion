// GPS position of each residence, keyed like the photos in
// residence_images.dart (lowercase, no accents, letters+digits only).
// The server sends no coordinates yet, so they live here. To place a
// residence on the map: add a line below with its (latitude, longitude).
// A residence missing from this table simply shows no map.
import 'residence_images.dart';

const Map<String, (double, double)> _residenceLocations = {
  // Approximatif : centre de Hydra, a remplacer par la position exacte.
  'corail': (36.7426, 3.0420),
};

/// Returns the (latitude, longitude) of a residence, matching by id first
/// then by display name, or null if its position is unknown.
(double, double)? residenceLocation({String? id, String? name}) {
  for (final candidate in [id, name]) {
    if (candidate == null || candidate.trim().isEmpty) continue;
    final point = _residenceLocations[normalizeResidenceKey(candidate)];
    if (point != null) return point;
  }
  return null;
}
