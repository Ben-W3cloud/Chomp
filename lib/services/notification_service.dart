/// Local notification service.
///
/// Handles displaying notifications on the device using
/// flutter_local_notifications. This is used for:
/// - Scan completion alerts
/// - Security score drop warnings
/// - New findings discovered during scans
///
/// Push notifications from Firebase (FCM) are received by [FcmService]
/// and displayed using this service.

library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for showing local notifications on the device.
///
/// Initializes the notification plugin and creates the notification
/// channel for Android. All notifications use the 'chomp_alerts'
/// channel with high importance.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes the notification plugin.
  ///
  /// Creates the Android notification channel and requests iOS permissions.
  /// Safe to call multiple times — only initializes once.
  Future<void> init() async {
    if (_initialized) return;

    // Platform-specific initialization settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create Android notification channel for high-priority alerts
    const channel = AndroidNotificationChannel(
      'chomp_alerts',
      'Repo Alerts',
      description: 'New issues or score changes found during a scan',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Displays a notification to the user.
  ///
  /// [title] is the notification headline.
  /// [body] is the notification content.
  ///
  /// Uses the current timestamp as the notification ID, so each
  /// notification appears as a separate entry in the system tray.
  Future<void> showAlert({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'chomp_alerts',
      'Repo Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
