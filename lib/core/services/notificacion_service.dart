
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'ice_cream_notifications',
    'Notificaciones ICE CREAM',
    description: 'Avisos de inicio de sesión y pronósticos',
    importance: Importance.max,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    // Las notificaciones locales se inicializan solamente en Android.
    // En Web evitamos Firebase Messaging y el registro del Service Worker.
    if (kIsWeb) {
      debugPrint(
        'Notificaciones desactivadas en Web por el momento.',
      );
      return;
    }

    if (_initialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const initializationSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();

      await androidPlugin?.createNotificationChannel(_channel);

      _initialized = true;

      debugPrint('Servicio de notificaciones inicializado.');
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) {
      debugPrint('Notificación omitida: plataforma no compatible o servicio no inicializado.');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'ice_cream_notifications',
        'Notificaciones ICE CREAM',
        channelDescription: 'Avisos de la aplicación',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
    }
  }

  Future<void> notifyLogin() async {
    await showNotification(
      id: 1,
      title: '¡Bienvenido a ICE CREAM!',
      body: 'Has iniciado sesión correctamente.',
    );
  }

  Future<void> notifyForecastReady() async {
    await showNotification(
      id: 2,
      title: '¡Tus gráficas están listas!',
      body: 'El pronóstico de demanda se ha generado correctamente.',
    );
  }
}
