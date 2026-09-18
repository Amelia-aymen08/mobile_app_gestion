// Verification hors application du faux serveur : on rejoue exactement ce que
// fait ApiService.getMyProperties, pour s'assurer que la forme de la reponse
// et le filtre sur owner.email laissent bien passer les biens.
//
// A RETIRER AVANT LA MISE EN PRODUCTION, avec le reste du mode demonstration.
//
// Lancement : dart run tool/check_demo.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../lib/data/demo_client.dart';

Future<void> main() async {
  for (final email in ['un.bien@demo.dz', 'trois.biens@demo.dz']) {
    final profile = demoProfileFor(email, demoPassword);
    if (profile == null) {
      print('ECHEC : identifiants refuses pour $email');
      continue;
    }
    final client = DemoClient(profile);

    // Meme traitement que getMyProperties.
    final res = await client
        .get(Uri.parse('https://exemple.test/api/properties'));
    final decoded = jsonDecode(res.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    final list = data is List ? data : [];
    final lower = email.toLowerCase().trim();
    final mine = list.where((p) {
      if (p is! Map) return false;
      final owner =
          (p['owner']?['email'] ?? '').toString().toLowerCase().trim();
      return owner == lower;
    }).toList();

    print('\n=== $email ===');
    print('statut HTTP        : ${res.statusCode}');
    print('biens dans data    : ${list.length}');
    print('biens apres filtre : ${mine.length}');
    for (final p in mine) {
      final r = p['Residence'] as Map;
      print('  - ${r['name']} | lot ${p['lotNumber']} | etage ${p['floor']} '
          '| ${p['surface']} m2 | ${r['address']}');
    }

    // Les autres appels de l'accueil.
    final sum = jsonDecode((await client.get(
            Uri.parse('https://exemple.test/api/financial/my-charges-summary')))
        .body);
    print('resume charges     : ${sum['annualAmount']} DZD, '
        'echeance dans ${sum['daysRemaining']} j');
    final tickets = jsonDecode(
        (await client.get(Uri.parse('https://exemple.test/api/maintenance')))
            .body) as List;
    print('signalements       : ${tickets.length}');
  }
}
