import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads ONLY client-safe config. If you ever find yourself tempted to
/// add an API key or DB connection string here, stop — it belongs in
/// server/.env instead, because anything in this file ships inside the
/// compiled app binary and can be extracted.
class Env {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get apiBaseUrl => _require('CHOMP_API_BASE_URL');
  static String get githubClientId => _require('GITHUB_CLIENT_ID');
  static String get githubCallbackScheme =>
      dotenv.env['GITHUB_CALLBACK_SCHEME'] ?? 'chomp';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env var: $key. Check your .env file.');
    }
    return value;
  }
}
