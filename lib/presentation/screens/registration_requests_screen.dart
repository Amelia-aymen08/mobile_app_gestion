import 'package:flutter/material.dart';
import '../../data/api_service.dart';

class RegistrationRequestsScreen extends StatefulWidget {
  const RegistrationRequestsScreen({super.key});

  @override
  State<RegistrationRequestsScreen> createState() => _RegistrationRequestsScreenState();
}

class _RegistrationRequestsScreenState extends State<RegistrationRequestsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final requests = await _apiService.getRegistrationRequests();
      setState(() {
        _requests = requests.where((r) => r['status'] == 'PENDING').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _handleAction(String id, bool approve) async {
    try {
      if (approve) {
        await _apiService.approveRequest(id);
      } else {
        await _apiService.rejectRequest(id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Demande approuvée' : 'Demande rejetée')),
        );
        _fetchRequests(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'inscription'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Aucune demande en attente.'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.person_add, color: Colors.orange),
                        ),
                        title: Text('${request['firstName']} ${request['lastName']}'),
                        subtitle: Text(request['email']),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailRow(Icons.phone, request['phone']),
                                const SizedBox(height: 8),
                                _detailRow(Icons.apartment, 'Résidence: ${request['residenceId']}'),
                                _detailRow(Icons.location_city, 'Bloc: ${request['block']} - Etage: ${request['floor']} - Porte: ${request['door']}'),
                                const SizedBox(height: 16),
                                OverflowBar(
                                  alignment: MainAxisAlignment.end,
                                  spacing: 8,
                                  overflowSpacing: 8,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _handleAction(request['id'].toString(), false),
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _handleAction(request['id'].toString(), true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Valider'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
