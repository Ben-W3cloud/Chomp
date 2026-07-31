import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// Loads the `.env` file into memory. Call this before accessing any
  /// environment variables, typically in `main()` before `runApp()`.
  static Future<void> load() => dotenv.load(fileName: '.env');

  /// The base URL of the Chomp backend API.
  /// All API requests are made to this URL + endpoint path.
  static String get apiBaseUrl => _require('CHOMP_API_BASE_URL');

  /// GitHub OAuth app client ID.
  /// Used to build the authorization URL for GitHub login.
  static String get githubClientId => _require('GITHUB_CLIENT_ID');

  /// Custom URL scheme for OAuth callback.
  /// The system browser redirects to this scheme after GitHub authorization.
  /// Defaults to 'chomp' if not specified in .env.
  static String get githubCallbackScheme =>
      dotenv.env['GITHUB_CALLBACK_SCHEME'] ?? 'chomp';

  /// Retrieves a required environment variable by key.
  /// Throws [StateError] if the variable is missing or empty.
  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env var: $key. Check your .env file.');
    }
    return value;
  }
}
