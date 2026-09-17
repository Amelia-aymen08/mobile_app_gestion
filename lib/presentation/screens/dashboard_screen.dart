import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  bool _loading = true;
  Map<String, dynamic> _data = {};

  String _frenchDate(DateTime date) {
    const weekdays = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getDashboard();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _data['stats'] is Map ? _data['stats'] as Map : const {};
    final weekly = _data['weeklyActivity'] is List
        ? _data['weeklyActivity'] as List
        : const [];
    final activities =
        _data['activities'] is List ? _data['activities'] as List : const [];
    final tickets = int.tryParse('${stats['ticketsCount'] ?? 0}') ?? 0;
    final residences = '${stats['totalResidences'] ?? 0}';
    final occupancy = '${stats['occupancyRate'] ?? '0%'}';
    final revenue = '${stats['monthlyRevenue'] ?? '0 DZD'}';

    return Scaffold(
      backgroundColor: brandCream,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: brandAmber))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(26, 18, 26, 110),
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text('Tableau de bord',
                                      style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                          color: brandNavy)),
                                  Text(_frenchDate(DateTime.now()),
                                      style: const TextStyle(
                                          fontSize: 11, color: brandGoldDark)),
                                ])),
                            _period('7j', false),
                            const SizedBox(width: 7),
                            _period('30j', true),
                            const SizedBox(width: 7),
                            _period('90j', false),
                          ]),
                      const SizedBox(height: 22),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.48,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _stat('TICKETS OUVERTS', '$tickets', '↘ 8%',
                              const Color(0xFFC62828)),
                          _stat('RÉSIDENCES', residences, '↗ 12%',
                              const Color(0xFF16823B)),
                          _stat('TAUX OCCUPATION', occupancy, '↗ 3%',
                              const Color(0xFF16823B),
                              accent: true),
                          _stat('REVENUS', revenue, '↘ 2%',
                              const Color(0xFFC62828)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _panel(
                          'ACTION REQUISE',
                          Column(
                              children: activities.take(3).map((row) {
                            final item = row is Map ? row : const {};
                            return _action(
                                '${item['action'] ?? 'Activité récente'}',
                                '${item['user'] ?? ''}');
                          }).toList())),
                      const SizedBox(height: 20),
                      _panel(
                          'VOLUME DE TICKETS — 7 DERNIERS JOURS',
                          SizedBox(
                              height: 170,
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: weekly.take(7).map((row) {
                                    final item = row is Map ? row : const {};
                                    final count = int.tryParse(
                                            '${item['tickets'] ?? 0}') ??
                                        0;
                                    return Expanded(
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Expanded(
                                                      child: Align(
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                          child: Container(
                                                              height: 18.0 +
                                                                  count * 9,
                                                              width: 17,
                                                              color: const Color(
                                                                  0xFFB84D00)))),
                                                  const SizedBox(height: 7),
                                                  Text('${item['name'] ?? ''}',
                                                      style: const TextStyle(
                                                          fontSize: 9,
                                                          color:
                                                              brandGoldDark)),
                                                ])));
                                  }).toList()))),
                      const SizedBox(height: 20),
                      _panel(
                          'ACTIVITÉ RÉCENTE',
                          Column(
                              children: activities.take(6).map((row) {
                            final item = row is Map ? row : const {};
                            return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: const BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Color(0xFFEAE4DA)))),
                                child: Row(children: [
                                  Expanded(
                                      child: Text('${item['action'] ?? ''}',
                                          style: const TextStyle(
                                              fontSize: 12, color: brandNavy))),
                                  Text('${item['time'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 9, color: brandGoldDark)),
                                ]));
                          }).toList())),
                    ]),
              ),
      ),
    );
  }

  Widget _period(String label, bool selected) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: selected ? brandAmber : Colors.transparent,
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? brandNavy : brandGoldDark)));

  Widget _stat(String title, String value, String change, Color changeColor,
          {bool accent = false}) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6DFD2)),
            borderRadius: BorderRadius.circular(4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: .8,
                        color: brandGoldDark,
                        fontWeight: FontWeight.w700))),
            Text(change, style: TextStyle(fontSize: 9, color: changeColor))
          ]),
          const Spacer(),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: accent ? brandAmber : brandNavy)),
          const SizedBox(height: 5),
          Align(
              alignment: Alignment.centerRight,
              child: CustomPaint(
                  size: const Size(55, 18),
                  painter: _SparkPainter(accent ? brandAmber : brandNavy))),
        ]),
      );

  Widget _panel(String title, Widget child) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6DFD2)),
            borderRadius: BorderRadius.circular(4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.all(14),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w800,
                      color: brandNavy))),
          const Divider(height: 1, color: Color(0xFFE6DFD2)),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ]),
      );

  Widget _action(String title, String subtitle) => Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAE4DA)))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFC62828), size: 17),
        const SizedBox(width: 9),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: brandNavy)),
          Text(subtitle,
              style: const TextStyle(fontSize: 9, color: brandGoldDark))
        ])),
        const CircleAvatar(radius: 4, backgroundColor: Color(0xFFC62828)),
      ]));
}

class _SparkPainter extends CustomPainter {
  final Color color;
  const _SparkPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * .7)
      ..lineTo(size.width * .2, size.height * .3)
      ..lineTo(size.width * .4, size.height * .75)
      ..lineTo(size.width * .65, size.height * .15)
      ..lineTo(size.width, size.height * .5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.color != color;
}
