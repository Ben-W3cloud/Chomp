import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants.dart';
import 'api_client.dart';
import 'notification_service.dart';

/// Registers this device with our backend so the hourly server-side
/// scan job knows where to send a push when it finds something worth
/// telling the user about.
class FcmService {
  final _api = ApiClient.instance;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) await _registerToken(token);
    messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Chomp';
      final body =
          message.notification?.body ?? 'A watched repo has an update.';
      NotificationService.instance.showAlert(title: title, body: body);
    });
  }

  Future<void> _registerToken(String token) async {
    await _api.post(ApiEndpoints.registerDevice, {'fcm_token': token});
  }
}
