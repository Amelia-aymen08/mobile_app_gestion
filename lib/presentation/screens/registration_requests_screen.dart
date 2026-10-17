import 'package:flutter/material.dart';

import '../../data/api_service.dart';
import 'admin/admin_request_card.dart';

/// Demandes d'inscription des residents, a valider ou rejeter.
class RegistrationRequestsScreen extends StatelessWidget {
  const RegistrationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    String name(Map r) {
      final full = '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.trim();
      return full.isEmpty ? (r['email'] ?? 'Demande').toString() : full;
    }

    return AdminRequestsPage(
      title: 'Inscriptions',
      icon: Icons.person_add_alt_rounded,
      emptyTitle: 'Rien à valider',
      emptyMessage: 'Les nouvelles demandes d\'inscription arriveront ici.',
      load: api.getRegistrationRequests,
      approve: (r) => api.approveRequest(r['id'].toString()),
      reject: (r, _) => api.rejectRequest(r['id'].toString()),
      titleOf: name,
      subtitleOf: (r) => (r['email'] ?? '').toString(),
      detailsOf: (r, residences) {
        final res = (r['residenceId'] ?? '').toString();
        final phone = (r['phone'] ?? '').toString().trim();
        return [
          if (res.isNotEmpty)
            (Icons.apartment_rounded, residences[res] ?? 'Résidence $res'),
          if (adminUnitLine(r).isNotEmpty)
            (Icons.door_front_door_outlined, adminUnitLine(r)),
          if (phone.isNotEmpty) (Icons.phone_outlined, phone),
          if (adminRequestDate(r['createdAt']).isNotEmpty)
            (Icons.schedule_rounded, adminRequestDate(r['createdAt'])),
        ];
      },
    );
  }
}
