import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class SystemNotificationService {
  SystemNotificationService._();

  static final SystemNotificationService instance = SystemNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;

  bool get permissionGranted => _permissionGranted;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

    try {
      await _plugin.initialize(initSettings).timeout(const Duration(seconds: 10));

      const androidChannel = AndroidNotificationChannel(
        'gestimou_default',
        'Gérance Immo Service',
        description: 'Notifications Gérance Immo Service',
        importance: Importance.high,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      final androidGranted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission()
          .timeout(const Duration(seconds: 10), onTimeout: () => false);

      final iosGranted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);

      _permissionGranted = (androidGranted ?? true) || (iosGranted ?? false);
      _initialized = true;
    } catch (_) {
      // Never let a plugin/permission hiccup keep the caller waiting forever.
      _initialized = true;
    }
  }

  /// Programme une notification pour plus tard.
  ///
  /// Sert au rappel « dans 24 h » d'un avis : le systeme la delivre meme si
  /// l'application n'a pas ete rouverte entre-temps. Sur le web il n'y a pas
  /// de planificateur : l'appel est sans effet et retourne false, a charge de
  /// l'ecran de le dire.
  Future<bool> scheduleIn({
    required String key,
    required String title,
    required String message,
    required Duration delay,
  }) async {
    if (kIsWeb) return false;
    if (!_initialized) await init();

    try {
      // La base de fuseaux n'est chargee qu'ici : elle ne sert qu'aux
      // notifications differees et pese quelques centaines de kilo-octets.
      tzdata.initializeTimeZones();
      final when = tz.TZDateTime.now(tz.local).add(delay);

      await _plugin.zonedSchedule(
        key.hashCode & 0x7fffffff,
        title,
        message,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gestimou_default',
            'Gérance Immo Service',
            channelDescription: 'Notifications Gérance Immo Service',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (_) {
      // Rappel differe indisponible (permission d'alarme refusee, plateforme
      // sans planificateur) : l'appelant en informe la personne.
      return false;
    }
  }

  Future<bool> checkPermission() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) return true;
    final granted = await impl.areNotificationsEnabled();
    _permissionGranted = granted ?? false;
    return _permissionGranted;
  }

  Future<void> show({
    required String key,
    required String title,
    required String message,
  }) async {
    if (!_initialized) {
      await init();
    }

    final id = key.hashCode.abs() % 2147483647;

    const androidDetails = AndroidNotificationDetails(
      'gestimou_default',
      'Gérance Immo Service',
      channelDescription: 'Notifications Gérance Immo Service',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await _plugin.show(id, title, message, details);
  }

  Future<void> showPermissionGuidance(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications désactivées'),
        content: const Text(
          'Les notifications sont désactivées pour cette application.\n\n'
          'Pour les recevoir, allez dans Paramètres > Applications > Gérance Immo Service > Notifications et activez-les.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
