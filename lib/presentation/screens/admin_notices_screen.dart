import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';

class AdminNoticesScreen extends StatefulWidget {
  const AdminNoticesScreen({super.key});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  final _api = ApiService();
  final _search = TextEditingController();
  List<dynamic> _items = [];
  bool _loading = true;
  String _category = 'ALL';
  String _status = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _api.getManagedAnnouncements();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map> get _filtered => _items.whereType<Map>().where((item) {
        final query = _search.text.trim().toLowerCase();
        if (_category != 'ALL' && item['category'] != _category) return false;
        if (_status != 'ALL' && item['status'] != _status) return false;
        return query.isEmpty ||
            '${item['title']} ${item['residenceName']}'
                .toLowerCase()
                .contains(query);
      }).toList();

  Future<void> _newNotice() async {
    final title = TextEditingController();
    final body = TextEditingController();
    String category = 'INFO';
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: brandCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
                padding: EdgeInsets.fromLTRB(
                    26, 22, 26, MediaQuery.viewInsetsOf(context).bottom + 28),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nouvel avis',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: brandNavy)),
                      const SizedBox(height: 18),
                      TextField(
                          controller: title,
                          decoration:
                              const InputDecoration(labelText: 'Titre')),
                      const SizedBox(height: 12),
                      TextField(
                          controller: body,
                          maxLines: 4,
                          decoration:
                              const InputDecoration(labelText: 'Contenu')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(
                                value: 'URGENT', child: Text('Urgent')),
                            DropdownMenuItem(
                                value: 'INFO', child: Text('Info')),
                            DropdownMenuItem(
                                value: 'EVENT', child: Text('Événement')),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => category = value ?? 'INFO')),
                      const SizedBox(height: 20),
                      FilledButton(
                          onPressed: () async {
                            if (title.text.trim().isEmpty ||
                                body.text.trim().isEmpty) {
                              return;
                            }
                            await _api.createAnnouncement({
                              'title': title.text.trim(),
                              'body': body.text.trim(),
                              'category': category,
                              'status': 'PUBLISHED'
                            });
                            if (context.mounted) Navigator.pop(context, true);
                          },
                          child: const Text('Publier')),
                    ]),
              )),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandCream,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
            child: Row(children: [
              const Expanded(
                  child: Text('Avis & Annonces',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: brandNavy))),
              FilledButton.icon(
                  onPressed: _newNotice,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Nouvel avis'),
                  style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13))),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE6DFD2)),
          Expanded(
              child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(26, 16, 26, 110),
                      children: [
                        TextField(
                            controller: _search,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search, size: 18),
                                hintText:
                                    'Rechercher par titre ou résidence...'),
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['ALL', 'URGENT', 'INFO', 'EVENT']
                                .map((value) => _chip(
                                    value,
                                    _category == value,
                                    () => setState(() => _category = value),
                                    value == 'ALL'
                                        ? 'Tous types'
                                        : {
                                            'URGENT': 'Urgent',
                                            'INFO': 'Info',
                                            'EVENT': 'Événement'
                                          }[value]!))
                                .toList()),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'ALL',
                              'DRAFT',
                              'SCHEDULED',
                              'PUBLISHED',
                              'EXPIRED'
                            ]
                                .map((value) => _chip(
                                    value,
                                    _status == value,
                                    () => setState(() => _status = value),
                                    {
                                      'ALL': 'Tous statuts',
                                      'DRAFT': 'Brouillon',
                                      'SCHEDULED': 'Planifiée',
                                      'PUBLISHED': 'Publiée',
                                      'EXPIRED': 'Expirée'
                                    }[value]!))
                                .toList()),
                        const SizedBox(height: 22),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else if (_filtered.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: Text('Aucun avis.')))
                        else
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: const Color(0xFFE6DFD2)),
                                borderRadius: BorderRadius.circular(4)),
                            child: Column(
                                children: _filtered.map(_noticeRow).toList()),
                          ),
                      ]))),
        ]),
      ),
    );
  }

  Widget _chip(String value, bool selected, VoidCallback onTap, String label) =>
      InkWell(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
                color: selected
                    ? (value == 'ALL' && _category == value
                        ? brandAmber
                        : brandNavy)
                    : Colors.transparent,
                border: Border.all(color: const Color(0xFFDCCFB8)),
                borderRadius: BorderRadius.circular(2)),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : brandGoldDark))),
      );

  Widget _noticeRow(Map item) {
    final category = '${item['category'] ?? 'INFO'}';
    final colors = category == 'URGENT'
        ? const [Color(0xFFFFE7E7), Color(0xFFC62828)]
        : category == 'EVENT'
            ? const [Color(0xFFFFEAC8), Color(0xFFC76800)]
            : const [Color(0xFFF4F0E8), brandGoldDark];
    DateTime? date =
        DateTime.tryParse('${item['publishAt'] ?? item['createdAt'] ?? ''}');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEDE7DD)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            flex: 5,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  color: colors[0],
                  child: Text(
                      category == 'EVENT'
                          ? 'Événement'
                          : category[0] + category.substring(1).toLowerCase(),
                      style: TextStyle(
                          color: colors[1],
                          fontSize: 10,
                          fontWeight: FontWeight.w700))),
              const SizedBox(height: 5),
              Text('${item['title'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: brandNavy),
                  maxLines: 3),
            ])),
        Expanded(
            flex: 4,
            child: Text('${item['residenceName'] ?? 'Toutes résidences'}',
                style: const TextStyle(fontSize: 12, color: brandNavy))),
        Expanded(
            flex: 3,
            child: Text(
                date == null
                    ? '—'
                    : DateFormat('dd/MM/yyyy').format(date.toLocal()),
                style: const TextStyle(fontSize: 11, color: brandGoldDark))),
      ]),
    );
  }
}
