import 'package:flutter/material.dart';
import '../../data/api_service.dart';

class ResidentsListScreen extends StatefulWidget {
  const ResidentsListScreen({super.key});

  @override
  State<ResidentsListScreen> createState() => _ResidentsListScreenState();
}

class _ResidentsListScreenState extends State<ResidentsListScreen> {
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
      final data = await _api.getResidents();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final o = _items[index];
                    if (o is! Map) return const SizedBox.shrink();
                    final name = '${(o['firstName'] ?? '').toString()} ${(o['lastName'] ?? '').toString()}'.trim();
                    final residenceName = (o['residence'] is Map) ? (o['residence']['name']?.toString() ?? '') : '';
                    final block = (o['block'] ?? '').toString();
                    final floor = (o['floor'] ?? '').toString();
                    final door = (o['doorNumber'] ?? o['door'] ?? '').toString();

                    final subtitle = [
                      if (residenceName.isNotEmpty) residenceName,
                      if (block.isNotEmpty || floor.isNotEmpty || door.isNotEmpty) 'Bloc $block • Étage $floor • Porte $door'.replaceAll(RegExp(r'\s+'), ' ').trim(),
                    ].where((s) => s.trim().isNotEmpty).join('\n');

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.badge_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name.isEmpty ? 'Résident' : name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

