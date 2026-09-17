// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _userRole;
  List<dynamic> _residences = [];
  bool _isLoadingResidences = false;
  List<Map<String, String>> _intervenantOptions = [];
  bool _isLoadingIntervenants = false;
  String _ticketFilter = 'Tous';
  String _ticketQuery = '';

  String _formatDateTime(dynamic value) {
    try {
      if (value == null) return '';
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return value?.toString() ?? '';
    }
  }

  String? _mimeTypeForFilename(String filename) {
    final parts = filename.split('.');
    if (parts.length < 2) return null;
    final ext = parts.last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _userRole = context.read<AuthProvider>().userRole;
    _fetchTickets();
    _fetchResidences();
    if (_userRole == 'ADMIN' ||
        _userRole == 'MANAGER' ||
        _userRole == 'RESPONSABLE_ZONE') {
      _fetchIntervenants();
    }
  }

  Future<void> _fetchResidences() async {
    setState(() => _isLoadingResidences = true);
    try {
      final residences = await _apiService.getResidences();
      if (mounted) {
        setState(() {
          _residences = residences;
          _isLoadingResidences = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingResidences = false);
      }
    }
  }

  Future<void> _fetchIntervenants() async {
    setState(() => _isLoadingIntervenants = true);
    try {
      final results = await Future.wait([
        _apiService.getUsersByRole('RESPONSABLE_ZONE'),
        _apiService.getUsersByRole('MANAGER'),
        _apiService.getSubcontractors(),
        _apiService.getUsersByRole('INTERVENANT'),
      ]);

      final zones = results[0];
      final managers = results[1];
      final subs = results[2];
      final staffIntervenants = results[3];

      final options = <Map<String, String>>[];

      for (final s in subs) {
        if (s is! Map) continue;
        final id = (s['id'] ?? '').toString();
        final name = (s['name'] ?? '').toString();
        final specialty = (s['specialty'] ?? '').toString();
        if (id.isEmpty || name.isEmpty) continue;
        options.add({
          'value': 'sub:$id',
          'label': specialty.isNotEmpty ? '$name ($specialty)' : name,
        });
      }

      bool isSecurityManager(Map u) {
        final prof = (u['profession'] ?? '').toString().toLowerCase();
        return prof.contains('sécur') || prof.contains('secur');
      }

      for (final u in zones) {
        if (u is! Map) continue;
        final name = (u['name'] ?? '').toString();
        final zone = (u['zone'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final zoneLabel = zone.toUpperCase() == 'ALL' ? 'toutes les zones' : zone;
        options.add({
          'value': 'staff:$name',
          'label': zoneLabel.isNotEmpty
              ? '$name (Responsable $zoneLabel)'
              : '$name (Responsable de zone)',
        });
      }

      for (final u in managers) {
        if (u is! Map) continue;
        if (!isSecurityManager(u)) continue;
        final name = (u['name'] ?? '').toString();
        final prof = (u['profession'] ?? '').toString();
        if (name.isEmpty) continue;
        options.add({
          'value': 'staff:$name',
          'label': prof.isNotEmpty ? '$name ($prof)' : name,
        });
      }

      for (final u in staffIntervenants) {
        if (u is! Map) continue;
        final name = (u['name'] ?? '').toString();
        final prof = (u['profession'] ?? '').toString();
        if (name.isEmpty) continue;
        options.add({
          'value': 'staff:$name',
          'label': prof.isNotEmpty ? '$name ($prof)' : '$name (Intervenant)',
        });
      }

      if (mounted) {
        setState(() {
          _intervenantOptions = options;
          _isLoadingIntervenants = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingIntervenants = false);
      }
    }
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await _apiService.getTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _tickets.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _createTicket() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController =
        TextEditingController(text: 'Mon Appartement'); // Default
    String priority = 'Moyenne';
    String category = 'Plomberie';
    PlatformFile? attachment;

    // We need residenceId. For residents, we should pick their residence.
    // We can fetch properties to find residenceId.
    String? residenceId;
    List<dynamic> properties = [];

    final user = context.read<AuthProvider>().user;
    if (user != null) {
      if (_userRole == 'RESIDENT') {
        try {
          properties = await _apiService.getMyProperties(user['email']);
          if (properties.isNotEmpty) {
            residenceId = properties.first['residenceId'];
          }
        } catch (_) {}
      } else if (_userRole == 'RESPONSABLE_ZONE' ||
          _userRole == 'MANAGER' ||
          _userRole == 'ADMIN') {
        // Pre-select first available residence for staff roles
        if (_residences.isNotEmpty) {
          final first = _residences.first;
          if (first is Map) residenceId = (first['id'] ?? '').toString();
        }
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Nouveau Ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  value: residenceId,
                  decoration: const InputDecoration(labelText: 'Résidence'),
                  items: [
                    if (_userRole != 'RESIDENT')
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucune'),
                      ),
                    ..._residences.map((r) {
                      final id = (r is Map ? r['id'] : null)?.toString();
                      final name =
                          (r is Map ? r['name'] : null)?.toString() ?? id ?? '';
                      return DropdownMenuItem<String?>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                  ],
                  onChanged: _isLoadingResidences
                      ? null
                      : (v) => setState(() => residenceId = v),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Description (100 caractères max)'),
                  maxLines: 3,
                  maxLength: 100,
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                      labelText: 'Lieu (ex: Cuisine, Couloir)'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priorité'),
                  items: ['Basse', 'Moyenne', 'Haute', 'Urgent']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => priority = v!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: ['Plomberie', 'Electricité', 'Peinture', 'Autre']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pièce jointe (max 2 Mo)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: const [
                              'pdf',
                              'jpg',
                              'jpeg',
                              'png',
                              'webp',
                              'doc',
                              'docx',
                              'xls',
                              'xlsx'
                            ],
                            withData: true,
                          );
                          if (result == null || result.files.isEmpty) return;
                          final picked = result.files.first;
                          if (picked.bytes == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Impossible de lire le fichier sélectionné.')),
                            );
                            return;
                          }
                          if (picked.size > 2 * 1024 * 1024) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Fichier trop grand (max 2 Mo).')),
                            );
                            return;
                          }
                          final mime = _mimeTypeForFilename(picked.name);
                          if (mime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Type de fichier non supporté.')),
                            );
                            return;
                          }
                          setState(() => attachment = picked);
                        },
                        child: const Text('Choisir fichier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        attachment?.name ?? 'Aucun',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                try {
                  final desc = descController.text.trim();
                  final newTicket = <String, dynamic>{
                    'title': titleController.text,
                    'description':
                        desc.length > 100 ? desc.substring(0, 100) : desc,
                    'priority': priority,
                    'status': 'Signalé',
                    'category': category,
                    'location': locationController.text,
                  };

                  if (residenceId != null && residenceId!.isNotEmpty) {
                    newTicket['residenceId'] = residenceId;
                  }

                  final created = await _apiService.createTicket(newTicket);

                  if (attachment != null && attachment!.bytes != null) {
                    final mime = _mimeTypeForFilename(attachment!.name);
                    if (mime != null) {
                      try {
                        await _apiService.uploadTicketAttachment(
                          ticketId: created['id'].toString(),
                          bytes: attachment!.bytes!,
                          filename: attachment!.name,
                          mimeType: mime,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Ticket créé, mais upload PJ échoué: $e')),
                        );
                      }
                    }
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    _fetchTickets();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Ticket créé avec succès')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreateTicket = _userRole == 'RESIDENT' ||
        _userRole == 'ADMIN' ||
        _userRole == 'MANAGER' ||
        _userRole == 'RESPONSABLE_ZONE';
    final visibleTickets = _tickets.where((ticket) {
      if (ticket is! Map) return false;
      final status = '${ticket['status'] ?? ''}';
      if (_ticketFilter != 'Tous' && status != _ticketFilter) return false;
      final query = _ticketQuery.trim().toLowerCase();
      return query.isEmpty ||
          '${ticket['id']} ${ticket['title']}'.toLowerCase().contains(query);
    }).toList();
    return Scaffold(
      backgroundColor: brandCream,
      appBar: AppBar(
        title: const Text('Tickets',
            style: TextStyle(color: brandNavy, fontWeight: FontWeight.w800)),
        backgroundColor: brandCream,
        foregroundColor: brandNavy,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                  child: Text('${visibleTickets.length} / ${_tickets.length}',
                      style:
                          const TextStyle(color: brandGoldDark, fontSize: 12))))
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 10),
          child: TextField(
              onChanged: (value) => setState(() => _ticketQuery = value),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Rechercher par titre ou référence...')),
        ),
        SizedBox(
            height: 36,
            child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                children: [
                  'Tous',
                  'Signalé',
                  'En cours',
                  'Résolu',
                  'SAV',
                  'Rejeté'
                ].map((label) {
                  final selected = label == _ticketFilter;
                  return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                          onTap: () => setState(() => _ticketFilter = label),
                          child: Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 13),
                              decoration: BoxDecoration(
                                  color: selected
                                      ? brandAmber
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: const Color(0xFFDCCFB8)),
                                  borderRadius: BorderRadius.circular(2)),
                              child: Text(label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? brandNavy
                                          : brandGoldDark)))));
                }).toList())),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFE6DFD2)),
        Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleTickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Aucun ticket.'),
                            if (_userRole == 'RESIDENT')
                              ElevatedButton(
                                onPressed: _createTicket,
                                child: const Text('Créer un ticket'),
                              )
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: visibleTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = visibleTickets[index];
                          final residenceName = (ticket is Map &&
                                  ticket['residence'] is Map)
                              ? (ticket['residence']['name']?.toString() ?? '')
                              : '';
                          final status =
                              (ticket is Map ? ticket['status'] : null)
                                      ?.toString() ??
                                  '';
                          final priority =
                              (ticket is Map ? ticket['priority'] : null)
                                      ?.toString() ??
                                  '';
                          final statusColor = _getStatusColor(status);
                          return Card(
                            shape: RoundedRectangleBorder(
                                side:
                                    const BorderSide(color: Color(0xFFE6DFD2)),
                                borderRadius: BorderRadius.circular(4)),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 9),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _openTicketDetails(ticket),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 44,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                          _getCategoryIcon(ticket['category']),
                                          color: statusColor,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (ticket is Map
                                                    ? ticket['title']
                                                    : '')
                                                .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                      alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  priority,
                                                  style: const TextStyle(
                                                      color: Color(0xFF64748B),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (residenceName.isNotEmpty)
                                            Text(
                                              residenceName,
                                              style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (ticket is Map &&
                                              ticket['createdAt'] != null)
                                            Text(
                                              _formatDateTime(
                                                  ticket['createdAt']),
                                              style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 14, color: Color(0xFFCBD5E1)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )),
      ]),
      floatingActionButton: canCreateTicket
          ? FloatingActionButton(
              onPressed: _createTicket,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _openTicketDetails(dynamic ticket) async {
    if (!mounted) return;

    final bool canUpdate = _userRole == 'ADMIN' ||
        _userRole == 'MANAGER' ||
        _userRole == 'RESPONSABLE_ZONE' ||
        _userRole == 'INTERVENANT';
    final bool canAssign = _userRole == 'ADMIN' ||
        _userRole == 'MANAGER' ||
        _userRole == 'RESPONSABLE_ZONE';
    final bool canReject =
        _userRole == 'ADMIN' || _userRole == 'RESPONSABLE_ZONE';
    final bool isIntervenant = _userRole == 'INTERVENANT';
    final bool canTerminate =
        _userRole == 'ADMIN' || _userRole == 'RESPONSABLE_ZONE';

    String status =
        (ticket is Map ? ticket['status'] : null)?.toString() ?? 'Signalé';
    final String assigneeName =
        (ticket is Map ? ticket['assignee'] : null)?.toString() ?? '';
    final String subcontractorId =
        (ticket is Map ? ticket['subcontractorId'] : null)?.toString() ?? '';
    final dynamic subcontractorObj =
        (ticket is Map ? ticket['subcontractor'] : null);
    final String subcontractorObjId = subcontractorObj is Map
        ? (subcontractorObj['id'] ?? '').toString()
        : '';
    final rawIntervenantValue = subcontractorObjId.isNotEmpty
        ? 'sub:$subcontractorObjId'
        : (subcontractorId.isNotEmpty
            ? 'sub:$subcontractorId'
            : (assigneeName.isNotEmpty ? 'staff:$assigneeName' : ''));
    final allOptionValues =
        _intervenantOptions.map((o) => o['value'] ?? '').toSet();
    String intervenantValue = (rawIntervenantValue.isNotEmpty &&
            allOptionValues.contains(rawIntervenantValue))
        ? rawIntervenantValue
        : '';
    // Snapshot of the assignment as loaded, so we only send assignee/
    // subcontractorId to the backend if the user actually changed it here.
    // Sending them unchanged re-triggers the backend's assignment-ownership
    // check on every status-only update, which fails once someone else is
    // already the ticket's responsible (e.g. a specific-zone manager already
    // self-took it) — blocking a "toutes les zones" RESPONSABLE_ZONE from
    // ever changing status on tickets they didn't personally claim.
    final initialIntervenantValue = intervenantValue;

    // Fetch requester charge status for display
    String chargeStatus = '';
    final requesterEmail =
        (ticket is Map ? ticket['email'] : null)?.toString() ?? '';
    if (canReject && requesterEmail.isNotEmpty) {
      try {
        chargeStatus = await _apiService.getClientChargeStatus(requesterEmail);
      } catch (_) {}
    }

    if (!mounted) return;

    // Build allowed status list based on role
    List<String> allowedStatuses;
    if (isIntervenant) {
      allowedStatuses = ['En cours'];
      if (status != 'En cours') status = 'En cours';
    } else if (canTerminate) {
      allowedStatuses = ['Signalé', 'En cours', 'Terminé', 'SAV'];
    } else {
      allowedStatuses = ['Signalé', 'En cours', 'SAV'];
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text((ticket is Map ? ticket['title'] : '').toString()),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Description: ${(ticket is Map ? ticket['description'] : '')}'),
                const SizedBox(height: 8),
                Text('Lieu: ${(ticket is Map ? ticket['location'] : '')}'),
                Text('Catégorie: ${(ticket is Map ? ticket['category'] : '')}'),
                Text('Priorité: ${(ticket is Map ? ticket['priority'] : '')}'),
                const SizedBox(height: 8),
                if (canUpdate)
                  DropdownButtonFormField<String>(
                    value: allowedStatuses.contains(status)
                        ? status
                        : allowedStatuses.first,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: allowedStatuses
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => status = v ?? status),
                  )
                else
                  Text('Statut: $status'),
                if (canAssign)
                  DropdownButtonFormField<String>(
                    value: intervenantValue,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Intervenant'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: '', child: Text('Non assigné')),
                      ..._intervenantOptions
                          .map((opt) => DropdownMenuItem<String>(
                                value: opt['value'],
                                child: Text(opt['label'] ?? '',
                                    overflow: TextOverflow.ellipsis),
                              )),
                    ],
                    onChanged: _isLoadingIntervenants
                        ? null
                        : (v) => setState(() => intervenantValue = (v ?? '')),
                  )
                else if (assigneeName.isNotEmpty)
                  Text('Intervenant: $assigneeName'),
                const SizedBox(height: 12),
                if (ticket is Map &&
                    ticket['residence'] is Map &&
                    ticket['residence']['name'] != null)
                  Text('Résidence: ${ticket['residence']['name']}'),
                if (ticket is Map && ticket['requester'] != null)
                  Text('Demandé par: ${ticket['requester']}'),
                // Client charge status (visible to admin/zone manager)
                if (canReject && chargeStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.payment_rounded,
                        size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    const Text('Statut charges client : ',
                        style: TextStyle(fontSize: 13)),
                    Text(
                      chargeStatus,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: chargeStatus == 'Payé'
                            ? const Color(0xFF15803D)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ]),
                ],
                if (ticket is Map &&
                    ticket['rejectionReason'] != null &&
                    ticket['rejectionReason'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Motif de rejet : ${ticket['rejectionReason']}',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
                  ),
                ],
                if (ticket is Map && ticket['createdAt'] != null)
                  Text('Date: ${_formatDateTime(ticket['createdAt'])}'),
                if (ticket is Map &&
                    ticket['attachmentUrl'] != null &&
                    ticket['attachmentUrl'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                      'Pièce jointe: ${(ticket['attachmentName'] ?? '').toString().isEmpty ? 'Disponible' : ticket['attachmentName']}'),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: () async {
                      final uploadsBase = _apiService.baseUrl
                          .replaceAll(RegExp(r'/api/?$'), '');
                      final url = '$uploadsBase${ticket['attachmentUrl']}';
                      await Clipboard.setData(ClipboardData(text: url));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lien copié.')));
                    },
                    child: const Text('Copier le lien'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer')),
            // Reject button
            if (canReject && status != 'Terminé' && status != 'Rejeté')
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _rejectTicket(ticket, chargeStatus);
                },
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626)),
                child: const Text('Rejeter',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            if (canUpdate || canAssign)
              ElevatedButton(
                onPressed: () async {
                  try {
                    final id =
                        (ticket is Map ? ticket['id'] : null)?.toString();
                    if (id == null) return;
                    final payload = <String, dynamic>{'status': status};
                    if (canAssign && intervenantValue != initialIntervenantValue) {
                      if (intervenantValue.isEmpty) {
                        payload['assignee'] = null;
                        payload['subcontractorId'] = null;
                      } else if (intervenantValue.startsWith('sub:')) {
                        payload['subcontractorId'] =
                            intervenantValue.substring(4);
                        payload['assignee'] = null;
                      } else if (intervenantValue.startsWith('staff:')) {
                        payload['assignee'] = intervenantValue.substring(6);
                        payload['subcontractorId'] = null;
                      }
                    }
                    final updated = await _apiService.updateTicket(id, payload);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    this.setState(() {
                      _tickets = _tickets.map((t) {
                        if (t is Map && t['id']?.toString() == id) {
                          return {...Map<String, dynamic>.from(t), ...updated};
                        }
                        return t;
                      }).toList();
                    });
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Erreur: ${e.toString().replaceAll('Exception: ', '')}')));
                  }
                },
                child: const Text('Enregistrer'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectTicket(dynamic ticket, String chargeStatus) async {
    if (!mounted) return;
    final id = (ticket is Map ? ticket['id'] : null)?.toString();
    if (id == null) return;

    const reasons = [
      'Charges non payées',
      'Problème non justifié',
      'Hors périmètre de la copropriété',
      'Doublon de ticket existant',
    ];
    String? selectedReason;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rejeter le ticket',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chargeStatus.isNotEmpty) ...[
                Row(children: [
                  const Icon(Icons.payment_rounded,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  const Text('Statut charges : ',
                      style: TextStyle(fontSize: 13)),
                  Text(
                    chargeStatus,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: chargeStatus == 'Payé'
                          ? const Color(0xFF15803D)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
              const Text('Motif du rejet :',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              ...reasons.map((r) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r, style: const TextStyle(fontSize: 13)),
                    value: r,
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFDC2626),
                    onChanged: (v) => setState(() => selectedReason = v),
                  )),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        final updated = await _apiService.updateTicket(id, {
                          'status': 'Rejeté',
                          'rejectionReason': selectedReason,
                        });
                        if (!mounted) return;
                        this.setState(() {
                          _tickets = _tickets.map((t) {
                            if (t is Map && t['id']?.toString() == id) {
                              return {
                                ...Map<String, dynamic>.from(t),
                                ...updated
                              };
                            }
                            return t;
                          }).toList();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ticket rejeté.')));
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Erreur: ${e.toString().replaceAll('Exception: ', '')}')));
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626)),
              child: const Text('Rejeter',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Signalé':
        return Colors.orange;
      case 'En cours':
        return Colors.blue;
      case 'Terminé':
        return Colors.green;
      case 'SAV':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Plomberie':
        return Icons.water_drop;
      case 'Electricité':
        return Icons.bolt;
      case 'Peinture':
        return Icons.format_paint;
      default:
        return Icons.build;
    }
  }
}
