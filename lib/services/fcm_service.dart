/// Firebase Cloud Messaging service.
///
/// Handles push notifications for the app. This service:
/// - Requests notification permissions from the user
/// - Retrieves the FCM device token
/// - Registers the token with our backend
/// - Listens for incoming push notifications
/// - Displays local notifications when pushes arrive
///
/// The backend uses the registered FCM tokens to send push notifications
/// when scans discover new findings or when security scores drop.

import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants.dart';
import 'api_client.dart';
import 'notification_service.dart';

/// Service for managing Firebase Cloud Messaging.
///
/// Registers the device with the backend and handles incoming
/// push notifications. When a push arrives while the app is in
/// the foreground, it's displayed as a local notification.
class FcmService {
  final _api = ApiClient.instance;

  /// Initializes FCM and registers the device token with the backend.
  ///
  /// Requests notification permissions, gets the FCM token, and
  /// sends it to our backend for storage. Also sets up a listener
  /// for token refreshes (e.g., when the app is reinstalled).
  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Request notification permissions from the user
    await messaging.requestPermission();

    // Get the current FCM token
    final token = await messaging.getToken();
    if (token != null) await _registerToken(token);

    // Listen for token refreshes (e.g., app reinstall, token expiry)
    messaging.onTokenRefresh.listen(_registerToken);

    // Listen for incoming push notifications
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Chomp';
      final body =
          message.notification?.body ?? 'A watched repo has an update.';
      NotificationService.instance.showAlert(title: title, body: body);
    });
  }

  /// Registers an FCM token with the backend.
  ///
  /// The backend stores this token in the device_tokens table and
  /// uses it to send push notifications when alerts are triggered.
  Future<void> _registerToken(String token) async {
    await _api.post(ApiEndpoints.registerDevice, {'fcm_token': token});
  }
}
