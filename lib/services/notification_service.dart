import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:html' as html; 
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final List<Map<String, String>> _activeNotifications = [];
  List<Map<String, String>> get activeNotifications => _activeNotifications;

  // Stream pour alerter la vue en temps réel
  final _notificationStreamController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get onNotificationReceived => _notificationStreamController.stream;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    if (kIsWeb) {
      debugPrint("État initial permission notification : ${html.Notification.permission}");
      if (html.Notification.permission == 'default') {
        html.Notification.requestPermission().then((permission) {
          debugPrint("Résultat demande permission : $permission");
        });
      }
    }
    if (!kIsWeb) {
      const InitializationSettings settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _notificationsPlugin.initialize(settings);
    }
  }

  Future<String> showTestNotification() async {
    if (kIsWeb) {
      debugPrint("Test de notification demandé... Permission actuelle : ${html.Notification.permission}");
      
      if (html.Notification.permission == 'granted') {
        try {
          _playWebSound();
          html.Notification("🚀 Test de Notification", body: "Si vous voyez ce message et entendez un son, tout est prêt !");
          debugPrint("Notification de test envoyée avec succès.");
          return 'granted';
        } catch (e) {
          debugPrint("Erreur lors de l'envoi de la notification: $e");
          return 'error';
        }
      } else if (html.Notification.permission == 'denied') {
        debugPrint("Permission refusée par l'utilisateur.");
        return 'denied';
      } else {
        debugPrint("Demande de permission via test...");
        final permission = await html.Notification.requestPermission();
        debugPrint("Résultat de la demande : $permission");
        if (permission == 'granted') {
          html.Notification("✅ Notifications Activées", body: "Vous recevrez désormais vos rappels ici.");
          return 'granted';
        }
        return permission; // 'default' ou 'denied'
      }
    }
    return 'not_web';
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    
    if (kIsWeb) {
      final difference = scheduledDate.difference(now);

      if (difference.isNegative) {
        debugPrint("ALERTE : L'heure est déjà passée ($scheduledDate).");
        return;
      }

      debugPrint("Notification programmée dans ${difference.inSeconds} secondes (à ${scheduledDate.toLocal()}).");

      Future.delayed(difference, () {
        final nowCheck = DateTime.now();
        // On permet une marge de 5 minutes si l'ordi était en veille
        if (nowCheck.isAfter(scheduledDate.subtract(const Duration(seconds: 30))) && 
            nowCheck.isBefore(scheduledDate.add(const Duration(minutes: 5)))) {
          
          debugPrint("Tentative d'affichage de la notification (Permission: ${html.Notification.permission})");
          
          final notificationData = {
            'id': id.toString(),
            'title': title, 
            'content': "Il est ${nowCheck.hour}:${nowCheck.minute.toString().padLeft(2, '0')} - C'est l'heure : $title"
          };

          // Système de secours interne (UI)
          _notificationStreamController.add(notificationData);
          _playWebSound();

          if (html.Notification.permission == 'granted') {
            html.Notification(title, body: body);
            debugPrint("Notification affichée : $title");
            
            _activeNotifications.add(notificationData);
            notifyListeners(); 
          }
        } else {
          debugPrint("Délai expiré ou ordi trop tardif pour la notification de $title");
        }
      });
    } else {
      await _notificationsPlugin.zonedSchedule(
        id, title, body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('medication_channel', 'Rappels', importance: Importance.max),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!kIsWeb) {
      await _notificationsPlugin.cancel(id);
    }
    _activeNotifications.removeWhere((item) => item['id'] == id.toString());
    notifyListeners();
  }

  void removeNotificationByTitle(String title) {
    _activeNotifications.removeWhere((item) => item['title'] == title);
    notifyListeners();
  }

  void clearNotifications() {
    _activeNotifications.clear();
    notifyListeners();
  }

  void _playWebSound() {
    if (kIsWeb) {
      try {
        final audio = html.AudioElement('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
        audio.play();
      } catch (e) {
        debugPrint("Erreur lors de la lecture du son: $e");
      }
    }
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}