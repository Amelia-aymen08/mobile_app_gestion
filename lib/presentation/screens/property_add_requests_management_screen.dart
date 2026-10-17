import 'package:flutter/material.dart';

import '../../data/api_service.dart';
import 'admin/admin_request_card.dart';

/// Demandes d'ajout d'un bien par un resident deja inscrit.
class PropertyAddRequestsManagementScreen extends StatelessWidget {
  const PropertyAddRequestsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return AdminRequestsPage(
      title: 'Ajouts de biens',
      icon: Icons.add_home_work_rounded,
      emptyTitle: 'Rien à valider',
      emptyMessage: 'Les demandes d\'ajout de bien des résidents arriveront ici.',
      askReason: true,
      load: api.getPropertyAddRequests,
      approve: (r) => api.approvePropertyAddRequest(r['id'].toString()),
      reject: (r, reason) =>
          api.rejectPropertyAddRequest(r['id'].toString(), reason: reason),
      titleOf: (r) {
        final o = r['owner'] ?? r['user'];
        if (o is Map) {
          final full = '${o['firstName'] ?? ''} ${o['lastName'] ?? ''}'.trim();
          if (full.isNotEmpty) return full;
        }
        return (r['email'] ?? 'Demande').toString();
      },
      subtitleOf: (r) {
        final o = r['owner'] ?? r['user'];
        return o is Map ? (r['email'] ?? '').toString() : '';
      },
      detailsOf: (r, residences) {
        final res = (r['residenceId'] ?? '').toString();
        return [
          if (res.isNotEmpty)
            (Icons.apartment_rounded, residences[res] ?? 'Résidence $res'),
          if (adminUnitLine(r).isNotEmpty)
            (Icons.door_front_door_outlined, adminUnitLine(r)),
          if (adminRequestDate(r['createdAt']).isNotEmpty)
            (Icons.schedule_rounded, adminRequestDate(r['createdAt'])),
        ];
      },
      noteOf: (r) => (r['notes'] ?? '').toString(),
    );
  }
}
