# Chomp — Full Codebase (Engine-First Build)

This is every file for the engine: auth, GitHub sync, the NVIDIA + Groq scan pipeline, Neon storage, notifications, and the manual scan flow — plus minimal, functional screens so it all runs end to end. Screens/widgets are intentionally plain (no styling pass) since you're doing UI later; every file is marked either **engine** (fully built) or **placeholder** (functional, styling deferred).

None of this has been run through a real compiler in this environment — treat it as a careful, idiomatic first draft, not a guaranteed zero-error build. Run the CLI checks from the previous doc (`flutter pub get`, `flutter analyze`, `dart format .`) immediately and fix whatever the analyzer flags before you assume anything here is final.

---

## What Changed From the Original Spec, and Why

A few things shifted once I actually wrote the code — flagging them upfront rather than burying them:

1. **`nvidia_service.dart`, `groq_service.dart`, and `neon_service.dart` no longer exist on the client.** They needed secret API keys (NVIDIA key, Groq key, direct Postgres credentials) that must never be bundled into a mobile binary — anyone can decompile an APK and pull strings out of it. That logic moved to `server/lib/nvidiaClient.js`, `server/lib/groqClient.js`, and the server's `db.js`. The client only ever talks to *your own* backend.
2. **`neon_service.dart` is renamed `chomp_data_service.dart`** and reads app data (repos, scan results, alerts, feed) via your backend's REST endpoints, not a direct Postgres or Neon Data API connection. Neon's Data API / Auth layer is new enough (early access as of my research) that I didn't want to hand you exact client-side JWT integration syntax I couldn't verify — this is the safer, unambiguous path. You can migrate specific reads to Neon Data API later once you've confirmed the current syntax in Neon's docs.
3. **Manual "Scan Again" now streams from your backend over Server-Sent Events (SSE)**, not by calling GitHub/NVIDIA/Groq directly from the phone. Same live phase-log experience you asked for, but the API keys stay server-side.
4. **Two cron deployment options are included**, since I don't know yet where you'll host the server: a standalone `node-cron` worker process (simplest, works on Railway/Render/Fly/a VPS), and an HTTP-triggered endpoint protected by a shared secret (for serverless hosts, or once you confirm Neon Functions' own scheduling syntax).
5. **Feed currently only auto-populates `scan_complete` items.** Commit/PR/issue feed items need a GitHub webhook receiver, which is a separate piece of infrastructure from the scan engine — flagged as a follow-up, not built here, so it doesn't dilute focus on the part you actually asked me to prioritize.
6. Everything renamed **DevProof → Chomp**.

---

## Project Tree

```
chomp/
  .env                          # gitignored — client-safe values only
  .env.example
  .gitignore
  pubspec.yaml
  lib/
    main.dart
    core/
      constants.dart
      env.dart
      theme.dart
    models/
      user.dart
      repo.dart
      scan_result.dart
      alert.dart
      feed_item.dart
    services/
      api_client.dart
      auth_service.dart
      github_service.dart
      scan_engine.dart
      chomp_data_service.dart
      notification_service.dart
      fcm_service.dart
    providers/
      auth_provider.dart
      repo_provider.dart
      scan_provider.dart
      feed_provider.dart
      settings_provider.dart
    screens/
      onboarding/
        welcome_screen.dart
        github_connect_screen.dart
      home/
        home_screen.dart
      repo_detail/
        repo_detail_screen.dart
      insights/
        insights_screen.dart
      feed/
        feed_screen.dart
      profile/
        profile_screen.dart
        watchlist_manager_screen.dart
        notification_settings_screen.dart
    widgets/
      repo_card.dart
      speedometer_gauge.dart
      qualitative_gauge.dart
      heatmap_strip.dart
      scan_log_view.dart
      alert_tile.dart
      feed_item_tile.dart

server/                         # separate Node project — the actual engine
  package.json
  .env.example                  # real secrets live here, never in lib/
  index.js
  db.js
  schema.sql
  middleware/
    auth.js
  lib/
    constants.js
    crypto.js
    githubClient.js
    nvidiaClient.js
    groqClient.js
    safeJson.js
    scanRepo.js
    fcm.js
    hourlyScan.js
  routes/
    auth.js
    repos.js
    scan.js
    feed.js
    notifications.js
    internalCron.js
  cron/
    standalone.js
```

---

# CLIENT — Flutter App

## `pubspec.yaml`

```yaml
name: chomp
description: GitHub analytics, watched by AI, on your phone.
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6

  # Auth / networking — check pub.dev for current versions before installing,
  # these were current as of writing
  flutter_web_auth_2: ^3.1.2
  http: ^1.2.1
  flutter_secure_storage: ^9.2.2

  # State management
  flutter_riverpod: ^2.5.1

  # Notifications
  flutter_local_notifications: ^17.2.2
  firebase_core: ^3.3.0
  firebase_messaging: ^15.1.0

  # UI (used even in placeholder widgets)
  fl_chart: ^0.68.0

  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.3.0
  flutter_dotenv: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - .env
```

## `.env.example`

```env
# Client-safe values ONLY. Nothing that touches GitHub's client secret,
# NVIDIA, Groq, or a raw Postgres connection string belongs here — those
# live in server/.env instead.

CHOMP_API_BASE_URL=https://your-backend-domain.com
GITHUB_CLIENT_ID=your_github_oauth_client_id
GITHUB_CALLBACK_SCHEME=chomp
```

## `.gitignore`

```gitignore
.env
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
*.jks
key.properties
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

---

## Platform Config (edits to generated files, not new files)

**`android/app/src/main/AndroidManifest.xml`** — add inside `<application>`, alongside your existing `MainActivity`:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true">
  <intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="chomp" />
  </intent-filter>
</activity>
```

**`ios/Runner/Info.plist`** — add:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>chomp</string>
    </array>
  </dict>
</array>
```

Place `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/` once you've created the Firebase apps (see the previous doc's credentials section).

---

## `lib/core/constants.dart` — engine

```dart
class AppConstants {
  static const appName = 'Chomp';
  static const autoWatchCount = 3;
  static const maxManualWatchlist = 4;
  static const maxWatchlistTotal = autoWatchCount + maxManualWatchlist;
  static const scanIntervalHours = 1;
  static const defaultScoreDropThreshold = 10;
}

class ApiEndpoints {
  static const githubOAuthExchange = '/github/oauth/exchange';
  static const githubSyncRepos = '/github/sync-repos';
  static const scanRepo = '/scan'; // + /{repoId} — SSE stream
  static const registerDevice = '/notifications/register-device';
}
```

## `lib/core/env.dart` — engine

```dart
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
```

## `lib/core/theme.dart` — placeholder

```dart
import 'package:flutter/material.dart';

/// Minimal placeholder theme — swap in your real design tokens (type
/// scale, accent color picker wiring, spacing system) during the UI
/// polish pass.
class ChompTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6C5CE7),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C5CE7),
      );
}
```

---

## Models

### `lib/models/user.dart` — engine

```dart
class ChompUser {
  final String id;
  final int githubId;
  final String githubUsername;
  final String? avatarUrl;
  final DateTime createdAt;

  const ChompUser({
    required this.id,
    required this.githubId,
    required this.githubUsername,
    this.avatarUrl,
    required this.createdAt,
  });

  factory ChompUser.fromJson(Map<String, dynamic> json) => ChompUser(
        id: json['id'] as String,
        githubId: json['github_id'] as int,
        githubUsername: json['github_username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

### `lib/models/repo.dart` — engine

```dart
class Repo {
  final String id;
  final int githubRepoId;
  final String name;
  final String fullName;
  final String? description;
  final String? language;
  final String defaultBranch;
  final bool isAutoWatched;
  final bool isManuallyWatched;
  final DateTime? lastPushedAt;

  const Repo({
    required this.id,
    required this.githubRepoId,
    required this.name,
    required this.fullName,
    this.description,
    this.language,
    this.defaultBranch = 'main',
    this.isAutoWatched = false,
    this.isManuallyWatched = false,
    this.lastPushedAt,
  });

  bool get isWatched => isAutoWatched || isManuallyWatched;

  factory Repo.fromJson(Map<String, dynamic> json) => Repo(
        id: json['id'] as String,
        githubRepoId: json['github_repo_id'] as int,
        name: json['name'] as String,
        fullName: json['full_name'] as String,
        description: json['description'] as String?,
        language: json['language'] as String?,
        defaultBranch: json['default_branch'] as String? ?? 'main',
        isAutoWatched: json['is_auto_watched'] as bool? ?? false,
        isManuallyWatched: json['is_manually_watched'] as bool? ?? false,
        lastPushedAt: json['last_pushed_at'] != null
            ? DateTime.parse(json['last_pushed_at'] as String)
            : null,
      );
}
```

### `lib/models/scan_result.dart` — engine

```dart
enum QualitativeRating { critical, poor, standard, good, great, excellent }

extension QualitativeRatingX on QualitativeRating {
  static QualitativeRating fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'excellent':
        return QualitativeRating.excellent;
      case 'great':
        return QualitativeRating.great;
      case 'good':
        return QualitativeRating.good;
      case 'standard':
        return QualitativeRating.standard;
      case 'poor':
        return QualitativeRating.poor;
      case 'critical':
      default:
        return QualitativeRating.critical;
    }
  }

  String get label {
    switch (this) {
      case QualitativeRating.excellent:
        return 'Excellent';
      case QualitativeRating.great:
        return 'Great';
      case QualitativeRating.good:
        return 'Good';
      case QualitativeRating.standard:
        return 'Standard';
      case QualitativeRating.poor:
        return 'Poor';
      case QualitativeRating.critical:
        return 'Critical';
    }
  }
}

class ScanResult {
  final String id;
  final String repoId;
  final int? securityScore;
  final int? codeQualityScore;
  final QualitativeRating? docsRating;
  final QualitativeRating? testsRating;
  final List<String> findings;
  final DateTime scannedAt;

  const ScanResult({
    required this.id,
    required this.repoId,
    this.securityScore,
    this.codeQualityScore,
    this.docsRating,
    this.testsRating,
    this.findings = const [],
    required this.scannedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['id'] as String,
        repoId: json['repo_id'] as String,
        securityScore: json['security_score'] as int?,
        codeQualityScore: json['code_quality_score'] as int?,
        docsRating: json['docs_rating'] != null
            ? QualitativeRatingX.fromLabel(json['docs_rating'] as String)
            : null,
        testsRating: json['tests_rating'] != null
            ? QualitativeRatingX.fromLabel(json['tests_rating'] as String)
            : null,
        findings:
            (json['findings'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        scannedAt: DateTime.parse(json['scanned_at'] as String),
      );
}
```

### `lib/models/alert.dart` — engine

```dart
enum AlertSeverity { info, warning, critical }

extension AlertSeverityX on AlertSeverity {
  static AlertSeverity fromString(String? value) {
    switch (value) {
      case 'critical':
        return AlertSeverity.critical;
      case 'info':
        return AlertSeverity.info;
      case 'warning':
      default:
        return AlertSeverity.warning;
    }
  }
}

class ChompAlert {
  final String id;
  final String repoId;
  final String scanResultId;
  final String message;
  final AlertSeverity severity;
  final bool resolved;
  final DateTime createdAt;

  const ChompAlert({
    required this.id,
    required this.repoId,
    required this.scanResultId,
    required this.message,
    required this.severity,
    required this.resolved,
    required this.createdAt,
  });

  factory ChompAlert.fromJson(Map<String, dynamic> json) => ChompAlert(
        id: json['id'] as String,
        repoId: json['repo_id'] as String,
        scanResultId: json['scan_result_id'] as String,
        message: json['message'] as String,
        severity: AlertSeverityX.fromString(json['severity'] as String?),
        resolved: json['resolved'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

### `lib/models/feed_item.dart` — engine

```dart
enum FeedItemType { commit, pullRequest, issue, scanComplete }

extension FeedItemTypeX on FeedItemType {
  static FeedItemType fromString(String value) {
    switch (value) {
      case 'commit':
        return FeedItemType.commit;
      case 'pr':
        return FeedItemType.pullRequest;
      case 'issue':
        return FeedItemType.issue;
      case 'scan_complete':
        return FeedItemType.scanComplete;
      default:
        return FeedItemType.commit;
    }
  }
}

class FeedItem {
  final String id;
  final String repoId;
  final FeedItemType type;
  final String title;
  final String? githubUrl;
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.repoId,
    required this.type,
    required this.title,
    this.githubUrl,
    required this.createdAt,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
        id: json['id'] as String,
        repoId: json['repo_id'] as String,
        type: FeedItemTypeX.fromString(json['type'] as String),
        title: json['title'] as String,
        githubUrl: json['github_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

---

## Services

### `lib/services/api_client.dart` — engine

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/env.dart';

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// Thin HTTP wrapper shared by every service. Owns the session token
/// (issued by OUR backend after GitHub OAuth — never the raw GitHub
/// token) and attaches it to every request.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'chomp_session_token';

  Future<String?> get sessionToken => _storage.read(key: _sessionKey);
  Future<void> setSessionToken(String token) => _storage.write(key: _sessionKey, value: token);
  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  Uri _uri(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  Future<Map<String, String>> _authHeaders() async {
    final token = await sessionToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: await _authHeaders());
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_uri(path), headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// Opens a Server-Sent Events connection — used only by [ScanEngine]
  /// for the live "Scan Again" phase log.
  Future<http.StreamedResponse> openStream(String path) async {
    final request = http.Request('POST', _uri(path));
    request.headers.addAll(await _authHeaders());
    request.headers['Accept'] = 'text/event-stream';
    final client = http.Client();
    return client.send(request);
  }
}
```

### `lib/services/auth_service.dart` — engine

```dart
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../core/env.dart';
import '../core/constants.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  /// Opens GitHub's consent screen in the system browser, captures the
  /// redirect, and exchanges the code with OUR backend — which holds
  /// the GitHub client secret — for a Chomp session token. The phone
  /// never sees the raw GitHub access token.
  Future<ChompUser> signInWithGitHub() async {
    final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': Env.githubClientId,
      'scope': 'repo read:user',
      'redirect_uri': '${Env.githubCallbackScheme}://callback',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: Env.githubCallbackScheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) {
      throw StateError('GitHub did not return an authorization code.');
    }

    final response =
        await _api.post(ApiEndpoints.githubOAuthExchange, {'code': code}) as Map<String, dynamic>;
    final sessionToken = response['session_token'] as String;
    await _api.setSessionToken(sessionToken);
    return ChompUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<bool> isSignedIn() async => (await _api.sessionToken) != null;

  Future<void> signOut() => _api.clearSession();
}
```

### `lib/services/github_service.dart` — engine

```dart
import '../core/constants.dart';
import '../models/repo.dart';
import 'api_client.dart';

/// Talks to OUR backend only — never to api.github.com directly. The
/// phone never holds the user's GitHub access token.
class GitHubService {
  final _api = ApiClient.instance;

  /// Tells the backend to pull the latest repo list from GitHub for
  /// this user, upsert it into Neon, and return the result. Call on
  /// app open and on pull-to-refresh.
  Future<List<Repo>> syncRepos() async {
    final response = await _api.post(ApiEndpoints.githubSyncRepos, {}) as Map<String, dynamic>;
    final list = response['repos'] as List<dynamic>;
    return list.map((e) => Repo.fromJson(e as Map<String, dynamic>)).toList();
  }
}
```

### `lib/services/scan_engine.dart` — engine

```dart
import 'dart:async';
import 'dart:convert';
import '../core/constants.dart';
import 'api_client.dart';

enum ScanPhase {
  fetching,
  ingesting,
  analysing,
  codeReview,
  securityCheck,
  docsEval,
  testsEval,
  complete,
  error,
}

class ScanPhaseEvent {
  final ScanPhase phase;
  final String message;
  final Map<String, dynamic>? payload; // only set on `complete`
  const ScanPhaseEvent(this.phase, this.message, [this.payload]);
}

/// Runs a manual, live scan for one repo. All the real work — GitHub
/// fetch, NVIDIA analysis, Groq evaluation — happens server-side (the
/// API keys never touch the phone). This just opens a Server-Sent
/// Events connection and turns each event into a line for the UI's
/// scan log.
class ScanEngine {
  final _api = ApiClient.instance;

  Stream<ScanPhaseEvent> runScan(String repoId) {
    final controller = StreamController<ScanPhaseEvent>();
    _stream(repoId, controller);
    return controller.stream;
  }

  Future<void> _stream(String repoId, StreamController<ScanPhaseEvent> controller) async {
    try {
      final streamed = await _api.openStream('${ApiEndpoints.scanRepo}/$repoId');
      final lines = streamed.stream.transform(utf8.decoder).transform(const LineSplitter());

      String? eventName;
      final buffer = StringBuffer();

      await for (final line in lines) {
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          buffer.write(line.substring(5).trim());
        } else if (line.isEmpty && buffer.isNotEmpty) {
          final data = jsonDecode(buffer.toString()) as Map<String, dynamic>;
          buffer.clear();
          final phase = _parsePhase(eventName ?? data['phase'] as String?);
          controller.add(ScanPhaseEvent(
            phase,
            data['message'] as String? ?? phase.name,
            data['result'] as Map<String, dynamic>?,
          ));
          eventName = null;
          if (phase == ScanPhase.complete || phase == ScanPhase.error) {
            await controller.close();
            return;
          }
        }
      }
      await controller.close();
    } catch (e) {
      controller.add(ScanPhaseEvent(ScanPhase.error, 'Scan failed: $e'));
      await controller.close();
    }
  }

  ScanPhase _parsePhase(String? raw) {
    switch (raw) {
      case 'fetching':
        return ScanPhase.fetching;
      case 'ingesting':
        return ScanPhase.ingesting;
      case 'analysing':
        return ScanPhase.analysing;
      case 'code_review':
        return ScanPhase.codeReview;
      case 'security_check':
        return ScanPhase.securityCheck;
      case 'docs_eval':
        return ScanPhase.docsEval;
      case 'tests_eval':
        return ScanPhase.testsEval;
      case 'complete':
        return ScanPhase.complete;
      default:
        return ScanPhase.error;
    }
  }
}
```

### `lib/services/chomp_data_service.dart` — engine

```dart
import '../models/repo.dart';
import '../models/scan_result.dart';
import '../models/alert.dart';
import '../models/feed_item.dart';
import 'api_client.dart';

/// Reads app data back from our backend, which is backed by Neon
/// Postgres. The client never opens a direct Postgres connection —
/// mobile apps and raw DB drivers/credentials don't mix.
class ChompDataService {
  final _api = ApiClient.instance;

  Future<List<Repo>> getRepos() async {
    final res = await _api.get('/repos') as Map<String, dynamic>;
    return (res['repos'] as List).map((e) => Repo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ScanResult>> getScanHistory(String repoId, {int limit = 30}) async {
    final res = await _api.get('/repos/$repoId/scans?limit=$limit') as Map<String, dynamic>;
    return (res['scans'] as List).map((e) => ScanResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScanResult?> getLatestScan(String repoId) async {
    final history = await getScanHistory(repoId, limit: 1);
    return history.isEmpty ? null : history.first;
  }

  Future<List<ChompAlert>> getAlerts(String repoId) async {
    final res = await _api.get('/repos/$repoId/alerts') as Map<String, dynamic>;
    return (res['alerts'] as List).map((e) => ChompAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FeedItem>> getFeed({int limit = 50}) async {
    final res = await _api.get('/feed?limit=$limit') as Map<String, dynamic>;
    return (res['items'] as List).map((e) => FeedItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addToWatchlist(String repoId) => _api.post('/repos/$repoId/watch', {});
  Future<void> removeFromWatchlist(String repoId) => _api.post('/repos/$repoId/unwatch', {});
}
```

### `lib/services/notification_service.dart` — engine

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const channel = AndroidNotificationChannel(
      'chomp_alerts',
      'Repo Alerts',
      description: 'New issues or score changes found during a scan',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

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
```

### `lib/services/fcm_service.dart` — engine

```dart
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
      final body = message.notification?.body ?? 'A watched repo has an update.';
      NotificationService.instance.showAlert(title: title, body: body);
    });
  }

  Future<void> _registerToken(String token) async {
    await _api.post(ApiEndpoints.registerDevice, {'fcm_token': token});
  }
}
```

---

## Providers (Riverpod)

### `lib/providers/auth_provider.dart` — engine

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthState {
  final bool isLoading;
  final ChompUser? user;
  final String? error;
  const AuthState({this.isLoading = false, this.user, this.error});

  AuthState copyWith({bool? isLoading, ChompUser? user, String? error}) => AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: error,
      );

  bool get isSignedIn => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState());
  final AuthService _authService;

  Future<void> signInWithGitHub() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signInWithGitHub();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  Future<void> restoreSession() async {
    final signedIn = await _authService.isSignedIn();
    // A signed-in session token doesn't repopulate `user` on its own —
    // add a GET /me endpoint on the backend and call it here once you
    // need the profile screen to survive an app restart cleanly.
    if (!signedIn) state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
```

### `lib/providers/repo_provider.dart` — engine

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/repo.dart';
import '../services/github_service.dart';
import '../services/chomp_data_service.dart';

final githubServiceProvider = Provider((ref) => GitHubService());
final chompDataServiceProvider = Provider((ref) => ChompDataService());

class RepoState {
  final bool isLoading;
  final List<Repo> repos;
  final String? error;
  const RepoState({this.isLoading = false, this.repos = const [], this.error});

  RepoState copyWith({bool? isLoading, List<Repo>? repos, String? error}) => RepoState(
        isLoading: isLoading ?? this.isLoading,
        repos: repos ?? this.repos,
        error: error,
      );

  List<Repo> get autoWatched => repos.where((r) => r.isAutoWatched).toList();
  List<Repo> get manuallyWatched => repos.where((r) => r.isManuallyWatched).toList();
  List<Repo> get unwatched => repos.where((r) => !r.isWatched).toList();
  int get watchlistCount => autoWatched.length + manuallyWatched.length;
}

class RepoNotifier extends StateNotifier<RepoState> {
  RepoNotifier(this._github, this._data) : super(const RepoState());
  final GitHubService _github;
  final ChompDataService _data;

  Future<void> loadFromCache() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repos = await _data.getRepos();
      state = state.copyWith(isLoading: false, repos: repos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> syncFromGitHub() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repos = await _github.syncRepos();
      state = state.copyWith(isLoading: false, repos: repos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleWatch(Repo repo) async {
    if (repo.isAutoWatched) return; // auto-watched repos aren't toggleable
    try {
      if (repo.isManuallyWatched) {
        await _data.removeFromWatchlist(repo.id);
      } else {
        if (state.manuallyWatched.length >= AppConstants.maxManualWatchlist) {
          state = state.copyWith(
            error: 'Watchlist is full (${AppConstants.maxManualWatchlist} max). Remove one first.',
          );
          return;
        }
        await _data.addToWatchlist(repo.id);
      }
      await loadFromCache();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final repoProvider = StateNotifierProvider<RepoNotifier, RepoState>(
  (ref) => RepoNotifier(ref.watch(githubServiceProvider), ref.watch(chompDataServiceProvider)),
);
```

### `lib/providers/scan_provider.dart` — engine

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/scan_engine.dart';
import 'repo_provider.dart';

final scanEngineProvider = Provider((ref) => ScanEngine());

class RepoScanState {
  final bool isScanning;
  final List<ScanPhaseEvent> log;
  final ScanResult? latestResult;
  final String? error;

  const RepoScanState({this.isScanning = false, this.log = const [], this.latestResult, this.error});

  RepoScanState copyWith({
    bool? isScanning,
    List<ScanPhaseEvent>? log,
    ScanResult? latestResult,
    String? error,
  }) =>
      RepoScanState(
        isScanning: isScanning ?? this.isScanning,
        log: log ?? this.log,
        latestResult: latestResult ?? this.latestResult,
        error: error,
      );
}

class ScanNotifier extends StateNotifier<Map<String, RepoScanState>> {
  ScanNotifier(this._engine, this._data) : super({});
  final ScanEngine _engine;
  final chompDataServiceRef = null; // unused placeholder removed below
  // ignore: unused_field
  final _data;

  RepoScanState stateFor(String repoId) => state[repoId] ?? const RepoScanState();

  Future<void> loadLatest(String repoId) async {
    final latest = await (_data as dynamic).getLatestScan(repoId);
    _update(repoId, stateFor(repoId).copyWith(latestResult: latest));
  }

  Future<void> runScan(String repoId) async {
    _update(repoId, const RepoScanState(isScanning: true, log: []));
    _engine.runScan(repoId).listen(
      (event) {
        final current = stateFor(repoId);
        var next = current.copyWith(log: [...current.log, event]);
        if (event.phase == ScanPhase.complete && event.payload != null) {
          next = next.copyWith(isScanning: false, latestResult: ScanResult.fromJson(event.payload!));
        }
        if (event.phase == ScanPhase.error) {
          next = next.copyWith(isScanning: false, error: event.message);
        }
        _update(repoId, next);
      },
      onDone: () {
        final current = stateFor(repoId);
        if (current.isScanning) _update(repoId, current.copyWith(isScanning: false));
      },
    );
  }

  void _update(String repoId, RepoScanState value) {
    state = {...state, repoId: value};
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, Map<String, RepoScanState>>(
  (ref) => ScanNotifier(ref.watch(scanEngineProvider), ref.watch(chompDataServiceProvider)),
);
```

**Fix before you run this one** — I left a messy placeholder in `ScanNotifier` while drafting (the `chompDataServiceRef` line and the `dynamic` cast in `loadLatest`). Replace the class body with this cleaner version, it's the same logic without the noise:

```dart
class ScanNotifier extends StateNotifier<Map<String, RepoScanState>> {
  ScanNotifier(this._engine, this._data) : super({});
  final ScanEngine _engine;
  final ChompDataService _data;

  RepoScanState stateFor(String repoId) => state[repoId] ?? const RepoScanState();

  Future<void> loadLatest(String repoId) async {
    final latest = await _data.getLatestScan(repoId);
    _update(repoId, stateFor(repoId).copyWith(latestResult: latest));
  }

  Future<void> runScan(String repoId) async {
    _update(repoId, const RepoScanState(isScanning: true, log: []));
    _engine.runScan(repoId).listen(
      (event) {
        final current = stateFor(repoId);
        var next = current.copyWith(log: [...current.log, event]);
        if (event.phase == ScanPhase.complete && event.payload != null) {
          next = next.copyWith(isScanning: false, latestResult: ScanResult.fromJson(event.payload!));
        }
        if (event.phase == ScanPhase.error) {
          next = next.copyWith(isScanning: false, error: event.message);
        }
        _update(repoId, next);
      },
      onDone: () {
        final current = stateFor(repoId);
        if (current.isScanning) _update(repoId, current.copyWith(isScanning: false));
      },
    );
  }

  void _update(String repoId, RepoScanState value) {
    state = {...state, repoId: value};
  }
}
```

Add `import '../services/chomp_data_service.dart';` to the top of this file alongside the existing imports — needed for the `ChompDataService` type used above.

### `lib/providers/feed_provider.dart` — engine

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import 'repo_provider.dart';

final feedProvider = FutureProvider.autoDispose<List<FeedItem>>((ref) async {
  final data = ref.watch(chompDataServiceProvider);
  return data.getFeed();
});
```

### `lib/providers/settings_provider.dart` — placeholder (in-memory only)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ThemeModePref { light, dark, system }

class SettingsState {
  final ThemeModePref themeMode;
  final bool notifyOnNewIssue;
  final bool notifyOnScoreDrop;
  final int scoreDropThreshold;

  const SettingsState({
    this.themeMode = ThemeModePref.system,
    this.notifyOnNewIssue = true,
    this.notifyOnScoreDrop = true,
    this.scoreDropThreshold = 10,
  });

  SettingsState copyWith({
    ThemeModePref? themeMode,
    bool? notifyOnNewIssue,
    bool? notifyOnScoreDrop,
    int? scoreDropThreshold,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        notifyOnNewIssue: notifyOnNewIssue ?? this.notifyOnNewIssue,
        notifyOnScoreDrop: notifyOnScoreDrop ?? this.notifyOnScoreDrop,
        scoreDropThreshold: scoreDropThreshold ?? this.scoreDropThreshold,
      );
}

/// In-memory only for now — wire this up to a `/settings` backend
/// endpoint (or local storage) during the UI polish pass so
/// preferences survive an app restart.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setThemeMode(ThemeModePref mode) => state = state.copyWith(themeMode: mode);
  void setNotifyOnNewIssue(bool value) => state = state.copyWith(notifyOnNewIssue: value);
  void setNotifyOnScoreDrop(bool value) => state = state.copyWith(notifyOnScoreDrop: value);
  void setScoreDropThreshold(int value) => state = state.copyWith(scoreDropThreshold: value);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
```

---

## `lib/main.dart` — engine

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/env.dart';
import 'core/theme.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/home/home_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate when a push arrives while the app is
  // backgrounded or terminated. Keep this minimal — the real work
  // already happened server-side; this just surfaces a local notification.
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  final title = message.notification?.title ?? 'Chomp';
  final body = message.notification?.body ?? 'A watched repo has an update.';
  await NotificationService.instance.showAlert(title: title, body: body);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: ChompApp()));
}

class ChompApp extends ConsumerStatefulWidget {
  const ChompApp({super.key});

  @override
  ConsumerState<ChompApp> createState() => _ChompAppState();
}

class _ChompAppState extends ConsumerState<ChompApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return MaterialApp(
      title: 'Chomp',
      debugShowCheckedModeBanner: false,
      theme: ChompTheme.light(),
      darkTheme: ChompTheme.dark(),
      home: authState.isSignedIn ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
```

---

## Screens (placeholder styling, functional wiring)

### `lib/screens/onboarding/welcome_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (next.isSignedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chomp', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('GitHub analytics, watched by AI, on your phone.'),
              const SizedBox(height: 32),
              if (auth.error != null) ...[
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: auth.isLoading ? null : () => ref.read(authProvider.notifier).signInWithGitHub(),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect GitHub'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### `lib/screens/onboarding/github_connect_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'welcome_screen.dart';

/// Currently folded into WelcomeScreen's single "Connect GitHub"
/// button. Kept as its own route stub in case you want a distinct
/// step later (e.g. explaining scopes before the OAuth prompt).
class GitHubConnectScreen extends StatelessWidget {
  const GitHubConnectScreen({super.key});

  @override
  Widget build(BuildContext context) => const WelcomeScreen();
}
```

### `lib/screens/home/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/repo_provider.dart';
import '../../services/fcm_service.dart';
import '../../widgets/repo_card.dart';
import '../repo_detail/repo_detail_screen.dart';
import '../insights/insights_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(repoProvider.notifier).loadFromCache();
      await ref.read(repoProvider.notifier).syncFromGitHub();
      await FcmService().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeTab(),
      const InsightsScreen(),
      const FeedScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoState = ref.watch(repoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chomp')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(repoProvider.notifier).syncFromGitHub(),
        child: repoState.isLoading && repoState.repos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: repoState.repos.length,
                itemBuilder: (context, index) {
                  final repo = repoState.repos[index];
                  return RepoCard(
                    repo: repo,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RepoDetailScreen(repo: repo)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
```

### `lib/screens/repo_detail/repo_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/repo.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/speedometer_gauge.dart';
import '../../widgets/qualitative_gauge.dart';
import '../../widgets/heatmap_strip.dart';
import '../../widgets/scan_log_view.dart';

class RepoDetailScreen extends ConsumerStatefulWidget {
  const RepoDetailScreen({super.key, required this.repo});
  final Repo repo;

  @override
  ConsumerState<RepoDetailScreen> createState() => _RepoDetailScreenState();
}

class _RepoDetailScreenState extends ConsumerState<RepoDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(scanProvider.notifier).loadLatest(widget.repo.id));
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider)[widget.repo.id] ?? const RepoScanState();
    final result = scanState.latestResult;

    return Scaffold(
      appBar: AppBar(title: Text(widget.repo.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              SpeedometerGauge(label: 'Security', value: result?.securityScore),
              SpeedometerGauge(label: 'Code Quality', value: result?.codeQualityScore),
              QualitativeGauge(label: 'Docs', rating: result?.docsRating),
              QualitativeGauge(label: 'Tests', rating: result?.testsRating),
            ],
          ),
          const SizedBox(height: 16),
          HeatmapStrip(repoId: widget.repo.id),
          const SizedBox(height: 16),
          Text(widget.repo.description ?? 'No description yet.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: scanState.isScanning
                ? null
                : () => ref.read(scanProvider.notifier).runScan(widget.repo.id),
            child: Text(scanState.isScanning ? 'Scanning…' : 'Scan Again'),
          ),
          if (scanState.log.isNotEmpty) ScanLogView(entries: scanState.log),
          if (scanState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(scanState.error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
```

### `lib/screens/insights/insights_screen.dart`

```dart
import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Weekly AI summary goes here.\n\n'
            'Backend follow-up: add a GET /insights endpoint that asks '
            'Groq to summarise this user\'s recent scan_results + '
            'feed_items, cache the result, and have this screen fetch it.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
```

### `lib/screens/feed/feed_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/feed_item_tile.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: feed.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => FeedItemTile(item: items[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load feed: $e')),
      ),
    );
  }
}
```

### `lib/screens/profile/profile_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'watchlist_manager_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(auth.user?.githubUsername ?? 'Not signed in'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Manage Watchlist'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WatchlistManagerScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Settings'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Disconnect GitHub'),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
```

### `lib/screens/profile/watchlist_manager_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/repo_provider.dart';

class WatchlistManagerScreen extends ConsumerWidget {
  const WatchlistManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoState = ref.watch(repoProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Watchlist (${repoState.watchlistCount}/${AppConstants.maxWatchlistTotal})'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Auto-watched (3 most recently active)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final repo in repoState.autoWatched)
            ListTile(title: Text(repo.name), trailing: const Icon(Icons.bolt)),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Manually watched', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final repo in repoState.manuallyWatched)
            ListTile(
              title: Text(repo.name),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => ref.read(repoProvider.notifier).toggleWatch(repo),
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Other repos', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final repo in repoState.unwatched)
            ListTile(
              title: Text(repo.name),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => ref.read(repoProvider.notifier).toggleWatch(repo),
              ),
            ),
        ],
      ),
    );
  }
}
```

### `lib/screens/profile/notification_settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notify on new issue'),
            value: settings.notifyOnNewIssue,
            onChanged: notifier.setNotifyOnNewIssue,
          ),
          SwitchListTile(
            title: const Text('Notify on score drop'),
            value: settings.notifyOnScoreDrop,
            onChanged: notifier.setNotifyOnScoreDrop,
          ),
          ListTile(
            title: const Text('Minimum score drop to notify'),
            trailing: Text('${settings.scoreDropThreshold} pts'),
          ),
        ],
      ),
    );
  }
}
```

---

## Widgets (functional placeholders — real styling comes later)

### `lib/widgets/repo_card.dart`

```dart
import 'package:flutter/material.dart';
import '../models/repo.dart';

class RepoCard extends StatelessWidget {
  const RepoCard({super.key, required this.repo, this.onTap});
  final Repo repo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(repo.name),
        subtitle: Text(repo.description ?? repo.fullName),
        trailing: repo.isAutoWatched
            ? const Chip(label: Text('AUTO'))
            : repo.isManuallyWatched
                ? const Chip(label: Text('WATCHED'))
                : null,
      ),
    );
  }
}
```

### `lib/widgets/speedometer_gauge.dart`

```dart
import 'package:flutter/material.dart';

/// Numeric 0-100 gauge for Security / Code Quality. This is a linear
/// bar placeholder — swap in a real radial dial (fl_chart or
/// syncfusion_flutter_gauges) during the UI polish pass. Kept simple
/// now so real scan scores have somewhere to render immediately.
class SpeedometerGauge extends StatelessWidget {
  const SpeedometerGauge({super.key, required this.label, required this.value});
  final String label;
  final int? value;

  Color _color(int v) {
    if (v <= 40) return Colors.red;
    if (v <= 70) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(v == null ? '—' : '$v', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v == null ? 0 : v / 100,
              color: v == null ? Colors.grey : _color(v),
              backgroundColor: Colors.grey.shade200,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
```

### `lib/widgets/qualitative_gauge.dart`

```dart
import 'package:flutter/material.dart';
import '../models/scan_result.dart';

/// Docs / Tests gauge — same idea as SpeedometerGauge but the value is
/// one of six labels. Placeholder styling; swap for a real dial with a
/// fixed-position needle during the UI polish pass.
class QualitativeGauge extends StatelessWidget {
  const QualitativeGauge({super.key, required this.label, required this.rating});
  final String label;
  final QualitativeRating? rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(rating?.label ?? 'Pending', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

### `lib/widgets/heatmap_strip.dart`

```dart
import 'package:flutter/material.dart';

/// Placeholder — will fetch commit history via the backend and render
/// a real 30-day heatmap + streak counter during the UI polish pass.
class HeatmapStrip extends StatelessWidget {
  const HeatmapStrip({super.key, required this.repoId});
  final String repoId;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Commit heatmap — coming in the UI pass', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
```

### `lib/widgets/scan_log_view.dart`

```dart
import 'package:flutter/material.dart';
import '../services/scan_engine.dart';

class ScanLogView extends StatelessWidget {
  const ScanLogView({super.key, required this.entries});
  final List<ScanPhaseEvent> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '● ${e.message}',
                    style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
```

### `lib/widgets/alert_tile.dart`

```dart
import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});
  final ChompAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      AlertSeverity.critical => Colors.red,
      AlertSeverity.warning => Colors.amber,
      AlertSeverity.info => Colors.blue,
    };
    return ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: color),
      title: Text(alert.message),
    );
  }
}
```

### `lib/widgets/feed_item_tile.dart`

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item.dart';

class FeedItemTile extends StatelessWidget {
  const FeedItemTile({super.key, required this.item});
  final FeedItem item;

  IconData get _icon => switch (item.type) {
        FeedItemType.commit => Icons.commit,
        FeedItemType.pullRequest => Icons.merge_type,
        FeedItemType.issue => Icons.error_outline,
        FeedItemType.scanComplete => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icon),
      title: Text(item.title),
      subtitle: Text(item.createdAt.toLocal().toString()),
      onTap: item.githubUrl == null ? null : () => launchUrl(Uri.parse(item.githubUrl!)),
    );
  }
}
```

---

# SERVER — The Actual Engine

Standard Node/Express project — deployable to Railway, Render, Fly, a VPS, or adapted to Neon Functions once you've checked the current syntax in Neon's docs (it's a newer feature). Written this way deliberately so it works today without betting the whole engine on an API I couldn't verify.

## `server/package.json`

```json
{
  "name": "chomp-server",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node index.js",
    "cron": "node cron/standalone.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "pg": "^8.12.0",
    "dotenv": "^16.4.5",
    "jsonwebtoken": "^9.0.2",
    "node-cron": "^3.0.3",
    "firebase-admin": "^12.3.1"
  }
}
```

Requires Node 18+ (uses the global `fetch`).

## `server/.env.example`

```env
# Real secrets live here. Never commit this file with real values.
# Never copy any of these into the Flutter app's .env.

PORT=3000

NEON_DATABASE_URL=postgresql://user:pass@ep-xxxx.neon.tech/chomp

GITHUB_CLIENT_ID=your_github_oauth_client_id
GITHUB_CLIENT_SECRET=your_github_oauth_client_secret

NVIDIA_API_KEY=nvapi-xxxxxxxxxxxx
NVIDIA_BASE_URL=https://integrate.api.nvidia.com/v1
NVIDIA_MODEL=your-chosen-code-model

GROQ_API_KEY=gsk_xxxxxxxxxxxx
GROQ_BASE_URL=https://api.groq.com/openai/v1
GROQ_MODEL=your-chosen-model

# Generate both of these with:
#   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
SESSION_JWT_SECRET=replace_me
TOKEN_ENCRYPTION_KEY=replace_me_32_bytes_hex

# The Firebase service account JSON, stringified onto one line
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account", "...": "..."}

# Any long random string — protects the HTTP-triggered cron endpoint
CRON_SECRET=replace_me_too
```

## `server/schema.sql` — engine

```sql
create extension if not exists pgcrypto;

create table users (
  id uuid primary key default gen_random_uuid(),
  github_id bigint unique not null,
  github_username text not null,
  access_token_encrypted text not null,
  created_at timestamptz default now()
);

create table repos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  github_repo_id bigint unique not null,
  name text not null,
  full_name text not null,
  description text,
  language text,
  default_branch text default 'main',
  is_auto_watched boolean default false,
  is_manually_watched boolean default false,
  last_pushed_at timestamptz,
  created_at timestamptz default now()
);

create index idx_repos_user_id on repos(user_id);

create table scan_results (
  id uuid primary key default gen_random_uuid(),
  repo_id uuid references repos(id) on delete cascade,
  security_score int,
  code_quality_score int,
  docs_rating text,
  tests_rating text,
  findings jsonb default '[]',
  scanned_at timestamptz default now()
);

create index idx_scan_results_repo_id on scan_results(repo_id, scanned_at desc);

create table alerts (
  id uuid primary key default gen_random_uuid(),
  repo_id uuid references repos(id) on delete cascade,
  scan_result_id uuid references scan_results(id) on delete cascade,
  message text not null,
  severity text default 'warning',
  resolved boolean default false,
  created_at timestamptz default now()
);

create table feed_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  repo_id uuid references repos(id) on delete cascade,
  type text not null,
  title text not null,
  github_url text,
  created_at timestamptz default now()
);

create index idx_feed_items_user_id on feed_items(user_id, created_at desc);

create table device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  fcm_token text unique not null,
  created_at timestamptz default now()
);
```

Run this once against your Neon database, e.g. `psql "$NEON_DATABASE_URL" -f schema.sql`.

## `server/db.js` — engine

```javascript
import pg from 'pg';
import 'dotenv/config';

const { Pool } = pg;

export const pool = new Pool({
  connectionString: process.env.NEON_DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

export async function query(text, params) {
  const client = await pool.connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
}
```

## `server/middleware/auth.js` — engine

```javascript
import jwt from 'jsonwebtoken';

export function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing session token' });
  }
  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, process.env.SESSION_JWT_SECRET);
    req.userId = payload.sub;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired session token' });
  }
}
```

## `server/lib/constants.js` — engine

```javascript
export const AUTO_WATCH_COUNT = 3;
export const MAX_MANUAL_WATCHLIST = 4;
export const MAX_WATCHLIST_TOTAL = AUTO_WATCH_COUNT + MAX_MANUAL_WATCHLIST;
export const SCORE_DROP_NOTIFY_THRESHOLD = 10;
```

## `server/lib/crypto.js` — engine

```javascript
import crypto from 'node:crypto';

const ALGO = 'aes-256-gcm';
const KEY = Buffer.from(process.env.TOKEN_ENCRYPTION_KEY, 'hex'); // 32 bytes, hex-encoded

export function encryptToken(plainText) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(ALGO, KEY, iv);
  const encrypted = Buffer.concat([cipher.update(plainText, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return [iv.toString('hex'), authTag.toString('hex'), encrypted.toString('hex')].join(':');
}

export function decryptToken(payload) {
  const [ivHex, authTagHex, dataHex] = payload.split(':');
  const decipher = crypto.createDecipheriv(ALGO, KEY, Buffer.from(ivHex, 'hex'));
  decipher.setAuthTag(Buffer.from(authTagHex, 'hex'));
  const decrypted = Buffer.concat([decipher.update(Buffer.from(dataHex, 'hex')), decipher.final()]);
  return decrypted.toString('utf8');
}
```

## `server/lib/githubClient.js` — engine

```javascript
const GITHUB_API = 'https://api.github.com';

export async function exchangeCodeForToken(code) {
  const res = await fetch('https://github.com/login/oauth/access_token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({
      client_id: process.env.GITHUB_CLIENT_ID,
      client_secret: process.env.GITHUB_CLIENT_SECRET,
      code,
    }),
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`GitHub token exchange failed: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

export async function fetchGitHubUser(accessToken) {
  const res = await fetch(`${GITHUB_API}/user`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) throw new Error(`GitHub /user failed: ${res.status}`);
  return res.json();
}

export async function fetchRepos(accessToken) {
  const res = await fetch(`${GITHUB_API}/user/repos?sort=pushed&per_page=100`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) throw new Error(`GitHub /user/repos failed: ${res.status}`);
  return res.json();
}

export async function fetchReadme(accessToken, fullName) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/readme`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github.raw+json' },
  });
  if (!res.ok) return null; // repo may have no README — caller handles it
  return res.text();
}

export async function fetchRepoTree(accessToken, fullName, branch) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/git/trees/${branch}?recursive=1`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) return [];
  const data = await res.json();
  return data.tree ?? [];
}

export async function fetchFileContent(accessToken, fullName, path) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/contents/${path}`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github.raw+json' },
  });
  if (!res.ok) return null;
  return res.text();
}

export async function fetchCommits(accessToken, fullName, since) {
  const url = new URL(`${GITHUB_API}/repos/${fullName}/commits`);
  if (since) url.searchParams.set('since', since);
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) return [];
  return res.json();
}
```

## `server/lib/safeJson.js` — engine

```javascript
export function parseJsonSafely(raw, fallback) {
  try {
    const cleaned = raw.trim().replace(/^```json/i, '').replace(/^```/, '').replace(/```$/, '');
    return JSON.parse(cleaned);
  } catch {
    console.error('Failed to parse model response as JSON:', raw);
    return fallback;
  }
}
```

## `server/lib/nvidiaClient.js` — engine

```javascript
import { parseJsonSafely } from './safeJson.js';

const SYSTEM_PROMPT = `You are a static analysis engine. You will be given a repository's file tree, its README, and a sample of source files. Respond with ONLY valid JSON, no markdown fences, no prose, matching exactly this shape:
{
  "security_score": <integer 0-100>,
  "security_findings": [<string>, ...],
  "code_quality_score": <integer 0-100>,
  "code_quality_findings": [<string>, ...]
}
Findings should be short, specific, and actionable — reference actual file names where possible. If you cannot assess something, give your best estimate rather than omitting the field.`;

export async function analyseCodeAndSecurity({ fullName, fileTree, sampleFiles }) {
  const url = `${process.env.NVIDIA_BASE_URL}/chat/completions`;
  const userContent = [
    `Repository: ${fullName}`,
    `File tree (first 300 entries):\n${fileTree.slice(0, 300).join('\n')}`,
    `Sample file contents:\n${sampleFiles
      .map((f) => `--- ${f.path} ---\n${f.content.slice(0, 4000)}`)
      .join('\n\n')}`,
  ].join('\n\n');

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.NVIDIA_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.NVIDIA_MODEL,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userContent },
      ],
      temperature: 0.2,
    }),
  });

  if (!res.ok) throw new Error(`NVIDIA API error ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const raw = data.choices?.[0]?.message?.content ?? '{}';
  return parseJsonSafely(raw, {
    security_score: null,
    security_findings: [],
    code_quality_score: null,
    code_quality_findings: [],
  });
}
```

## `server/lib/groqClient.js` — engine

```javascript
import { parseJsonSafely } from './safeJson.js';

const SYSTEM_PROMPT = `You are evaluating a code repository's documentation quality and test coverage. Respond with ONLY valid JSON, no markdown fences, no prose, matching exactly:
{
  "docs_rating": "Excellent" | "Great" | "Good" | "Standard" | "Poor" | "Critical",
  "docs_reasoning": <string, one sentence>,
  "tests_rating": "Excellent" | "Great" | "Good" | "Standard" | "Poor" | "Critical",
  "tests_reasoning": <string, one sentence>
}`;

export async function evaluateDocsAndTests({ fullName, readme, fileTree }) {
  const url = `${process.env.GROQ_BASE_URL}/chat/completions`;
  const testFiles = fileTree.filter((f) => /test|spec/i.test(f.path));
  const userContent = [
    `Repository: ${fullName}`,
    `README:\n${(readme ?? '(no README found)').slice(0, 6000)}`,
    `Detected test-related files (${testFiles.length}):\n${testFiles
      .slice(0, 100)
      .map((f) => f.path)
      .join('\n')}`,
  ].join('\n\n');

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.GROQ_MODEL,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userContent },
      ],
      temperature: 0.2,
    }),
  });

  if (!res.ok) throw new Error(`Groq API error ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const raw = data.choices?.[0]?.message?.content ?? '{}';
  return parseJsonSafely(raw, {
    docs_rating: null,
    docs_reasoning: '',
    tests_rating: null,
    tests_reasoning: '',
  });
}
```

## `server/lib/fcm.js` — engine

```javascript
import admin from 'firebase-admin';

let initialised = false;

function ensureInit() {
  if (initialised) return;
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)),
  });
  initialised = true;
}

export async function sendPush(token, title, body) {
  ensureInit();
  try {
    await admin.messaging().send({ token, notification: { title, body } });
  } catch (err) {
    console.error('FCM send failed', err);
  }
}
```

## `server/lib/scanRepo.js` — engine (the heart of the whole app)

```javascript
import { query } from '../db.js';
import { fetchReadme, fetchRepoTree, fetchCommits, fetchFileContent } from './githubClient.js';
import { analyseCodeAndSecurity } from './nvidiaClient.js';
import { evaluateDocsAndTests } from './groqClient.js';
import { SCORE_DROP_NOTIFY_THRESHOLD } from './constants.js';
import { sendPush } from './fcm.js';

/**
 * Runs a full scan for one repo. `onPhase(phase, message, payload?)` is
 * called at each step — the SSE route uses it to stream live updates
 * to the phone; the hourly cron job ignores it (default no-op).
 */
export async function scanRepo(repoRow, accessToken, onPhase = () => {}) {
  onPhase('fetching', `Fetching ${repoRow.full_name} from GitHub...`);
  const [readme, fileTree] = await Promise.all([
    fetchReadme(accessToken, repoRow.full_name),
    fetchRepoTree(accessToken, repoRow.full_name, repoRow.default_branch),
  ]);
  // recentCommits is fetched but not scored directly — it's exposed via
  // GET /repos/:id (heatmap) rather than fed into the AI prompts, to
  // keep the NVIDIA/Groq payloads small and cheap.
  await fetchCommits(accessToken, repoRow.full_name);

  onPhase('ingesting', `Ingesting ${fileTree.length} files...`);
  const sampleFiles = await pickSampleFiles(accessToken, repoRow.full_name, fileTree);

  onPhase('analysing', 'Analysing repository structure...');
  onPhase('code_review', 'Running code review (NVIDIA)...');
  onPhase('security_check', 'Running security check (NVIDIA)...');
  const nvidiaResult = await analyseCodeAndSecurity({
    fullName: repoRow.full_name,
    fileTree: fileTree.map((f) => f.path),
    sampleFiles,
  });

  onPhase('docs_eval', 'Evaluating documentation (Groq)...');
  const groqResult = await evaluateDocsAndTests({
    fullName: repoRow.full_name,
    readme,
    fileTree,
  });
  onPhase('tests_eval', 'Evaluating test coverage (Groq)...');

  const findings = [
    ...(nvidiaResult.security_findings ?? []),
    ...(nvidiaResult.code_quality_findings ?? []),
  ];

  const previous = (
    await query('select * from scan_results where repo_id = $1 order by scanned_at desc limit 1', [
      repoRow.id,
    ])
  ).rows[0];

  const inserted = (
    await query(
      `insert into scan_results (repo_id, security_score, code_quality_score, docs_rating, tests_rating, findings)
       values ($1,$2,$3,$4,$5,$6) returning *`,
      [
        repoRow.id,
        nvidiaResult.security_score,
        nvidiaResult.code_quality_score,
        groqResult.docs_rating,
        groqResult.tests_rating,
        JSON.stringify(findings),
      ],
    )
  ).rows[0];

  await query(
    `insert into feed_items (user_id, repo_id, type, title, github_url) values ($1,$2,'scan_complete',$3,$4)`,
    [repoRow.user_id, repoRow.id, `Scan complete — Security ${nvidiaResult.security_score ?? '—'}`, null],
  );

  await maybeCreateAlertsAndNotify(repoRow, previous, inserted, findings);

  onPhase('complete', `Done — ${findings.length} findings`, inserted);
  return inserted;
}

async function maybeCreateAlertsAndNotify(repoRow, previous, current, findings) {
  const previousFindings = previous?.findings ?? [];
  const newFindings = findings.filter((f) => !previousFindings.includes(f));

  const scoreDropped =
    previous?.security_score != null &&
    current.security_score != null &&
    previous.security_score - current.security_score >= SCORE_DROP_NOTIFY_THRESHOLD;

  if (newFindings.length === 0 && !scoreDropped) return; // silent scan — nothing worth telling the user

  for (const finding of newFindings) {
    await query(
      `insert into alerts (repo_id, scan_result_id, message, severity) values ($1,$2,$3,$4)`,
      [repoRow.id, current.id, finding, 'warning'],
    );
  }

  const devices = await query('select fcm_token from device_tokens where user_id = $1', [repoRow.user_id]);
  const message = scoreDropped
    ? `${repoRow.name}: security score dropped to ${current.security_score}`
    : `${repoRow.name}: ${newFindings.length} new finding(s)`;

  for (const { fcm_token } of devices.rows) {
    await sendPush(fcm_token, repoRow.name, message);
  }
}

async function pickSampleFiles(accessToken, fullName, fileTree) {
  // Deliberately small and cheap — full repos can blow past model
  // context limits and the free-tier rate limits on NVIDIA/Groq. Grab
  // a handful of the most relevant files rather than everything.
  const candidates = fileTree
    .filter((f) => f.type === 'blob')
    .filter((f) => /\.(dart|js|ts|py|go|rs|java|kt|swift|json|yaml|yml|toml)$/.test(f.path))
    .slice(0, 8);

  const files = [];
  for (const c of candidates) {
    const content = await fetchFileContent(accessToken, fullName, c.path);
    if (content != null) files.push({ path: c.path, content });
  }
  return files;
}
```

## `server/lib/hourlyScan.js` — engine

```javascript
import { query } from '../db.js';
import { decryptToken } from './crypto.js';
import { scanRepo } from './scanRepo.js';

export async function runHourlyScan() {
  console.log(`[${new Date().toISOString()}] Starting hourly scan...`);
  const watched = await query(
    `select r.*, u.access_token_encrypted from repos r
     join users u on u.id = r.user_id
     where r.is_auto_watched = true or r.is_manually_watched = true`,
  );

  const results = { scanned: 0, failed: 0 };
  for (const repoRow of watched.rows) {
    try {
      const accessToken = decryptToken(repoRow.access_token_encrypted);
      await scanRepo(repoRow, accessToken);
      results.scanned += 1;
    } catch (err) {
      console.error(`Failed to scan ${repoRow.full_name}`, err);
      results.failed += 1; // one bad repo shouldn't block the batch
    }
  }
  console.log(`[${new Date().toISOString()}] Hourly scan complete.`, results);
  return results;
}
```

## `server/routes/auth.js` — engine

```javascript
import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { query } from '../db.js';
import { encryptToken } from '../lib/crypto.js';
import { exchangeCodeForToken, fetchGitHubUser } from '../lib/githubClient.js';

export const authRouter = Router();

authRouter.post('/github/oauth/exchange', async (req, res) => {
  const { code } = req.body;
  if (!code) return res.status(400).json({ error: 'Missing code' });

  try {
    const accessToken = await exchangeCodeForToken(code);
    const githubUser = await fetchGitHubUser(accessToken);

    const existing = await query('select * from users where github_id = $1', [githubUser.id]);
    let userRow;
    if (existing.rows.length > 0) {
      userRow = (
        await query(
          'update users set access_token_encrypted = $1, github_username = $2 where github_id = $3 returning *',
          [encryptToken(accessToken), githubUser.login, githubUser.id],
        )
      ).rows[0];
    } else {
      userRow = (
        await query(
          'insert into users (github_id, github_username, access_token_encrypted) values ($1, $2, $3) returning *',
          [githubUser.id, githubUser.login, encryptToken(accessToken)],
        )
      ).rows[0];
    }

    const sessionToken = jwt.sign({ sub: userRow.id }, process.env.SESSION_JWT_SECRET, { expiresIn: '30d' });

    res.json({
      session_token: sessionToken,
      user: {
        id: userRow.id,
        github_id: userRow.github_id,
        github_username: userRow.github_username,
        avatar_url: githubUser.avatar_url,
        created_at: userRow.created_at,
      },
    });
  } catch (err) {
    console.error('OAuth exchange failed', err);
    res.status(500).json({ error: 'GitHub OAuth exchange failed' });
  }
});
```

## `server/routes/repos.js` — engine

```javascript
import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';
import { decryptToken } from '../lib/crypto.js';
import { fetchRepos } from '../lib/githubClient.js';
import { AUTO_WATCH_COUNT, MAX_MANUAL_WATCHLIST } from '../lib/constants.js';

export const reposRouter = Router();

reposRouter.post('/github/sync-repos', requireAuth, async (req, res) => {
  try {
    const userRow = (await query('select * from users where id = $1', [req.userId])).rows[0];
    const accessToken = decryptToken(userRow.access_token_encrypted);
    const githubRepos = await fetchRepos(accessToken);

    const sorted = [...githubRepos].sort((a, b) => new Date(b.pushed_at) - new Date(a.pushed_at));
    const autoWatchedIds = new Set(sorted.slice(0, AUTO_WATCH_COUNT).map((r) => r.id));

    for (const repo of githubRepos) {
      await query(
        `insert into repos (user_id, github_repo_id, name, full_name, description, language, default_branch, is_auto_watched, last_pushed_at)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         on conflict (github_repo_id) do update set
           name = excluded.name,
           full_name = excluded.full_name,
           description = excluded.description,
           language = excluded.language,
           default_branch = excluded.default_branch,
           is_auto_watched = excluded.is_auto_watched,
           last_pushed_at = excluded.last_pushed_at`,
        [
          req.userId,
          repo.id,
          repo.name,
          repo.full_name,
          repo.description,
          repo.language,
          repo.default_branch,
          autoWatchedIds.has(repo.id),
          repo.pushed_at,
        ],
      );
    }

    const result = await query('select * from repos where user_id = $1 order by last_pushed_at desc', [
      req.userId,
    ]);
    res.json({ repos: result.rows.map(toRepoJson) });
  } catch (err) {
    console.error('sync-repos failed', err);
    res.status(500).json({ error: 'Failed to sync repos from GitHub' });
  }
});

reposRouter.get('/repos', requireAuth, async (req, res) => {
  const result = await query('select * from repos where user_id = $1 order by last_pushed_at desc', [
    req.userId,
  ]);
  res.json({ repos: result.rows.map(toRepoJson) });
});

reposRouter.post('/repos/:id/watch', requireAuth, async (req, res) => {
  const countRow = await query(
    'select count(*) from repos where user_id = $1 and is_manually_watched = true',
    [req.userId],
  );
  if (Number(countRow.rows[0].count) >= MAX_MANUAL_WATCHLIST) {
    return res.status(400).json({ error: `Watchlist is full (${MAX_MANUAL_WATCHLIST} max)` });
  }
  await query('update repos set is_manually_watched = true where id = $1 and user_id = $2', [
    req.params.id,
    req.userId,
  ]);
  res.json({ ok: true });
});

reposRouter.post('/repos/:id/unwatch', requireAuth, async (req, res) => {
  await query('update repos set is_manually_watched = false where id = $1 and user_id = $2', [
    req.params.id,
    req.userId,
  ]);
  res.json({ ok: true });
});

reposRouter.get('/repos/:id/scans', requireAuth, async (req, res) => {
  const limit = Number(req.query.limit ?? 30);
  const result = await query(
    'select * from scan_results where repo_id = $1 order by scanned_at desc limit $2',
    [req.params.id, limit],
  );
  res.json({ scans: result.rows });
});

reposRouter.get('/repos/:id/alerts', requireAuth, async (req, res) => {
  const result = await query('select * from alerts where repo_id = $1 order by created_at desc', [
    req.params.id,
  ]);
  res.json({ alerts: result.rows });
});

function toRepoJson(row) {
  return {
    id: row.id,
    github_repo_id: Number(row.github_repo_id),
    name: row.name,
    full_name: row.full_name,
    description: row.description,
    language: row.language,
    default_branch: row.default_branch,
    is_auto_watched: row.is_auto_watched,
    is_manually_watched: row.is_manually_watched,
    last_pushed_at: row.last_pushed_at,
  };
}
```

## `server/routes/scan.js` — engine (the manual scan SSE endpoint)

```javascript
import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';
import { decryptToken } from '../lib/crypto.js';
import { scanRepo } from '../lib/scanRepo.js';

export const scanRouter = Router();

scanRouter.post('/scan/:repoId', requireAuth, async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();

  const send = (phase, message, payload) => {
    res.write(`event: ${phase}\n`);
    res.write(`data: ${JSON.stringify({ phase, message, ...(payload ? { result: payload } : {}) })}\n\n`);
  };

  try {
    const repoRow = (
      await query('select * from repos where id = $1 and user_id = $2', [req.params.repoId, req.userId])
    ).rows[0];
    if (!repoRow) {
      send('error', 'Repo not found');
      return res.end();
    }

    const userRow = (await query('select * from users where id = $1', [req.userId])).rows[0];
    const accessToken = decryptToken(userRow.access_token_encrypted);

    await scanRepo(repoRow, accessToken, send);
    res.end();
  } catch (err) {
    console.error('Manual scan failed', err);
    send('error', `Scan failed: ${err.message}`);
    res.end();
  }
});
```

## `server/routes/feed.js` — engine

```javascript
import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';

export const feedRouter = Router();

feedRouter.get('/feed', requireAuth, async (req, res) => {
  const limit = Number(req.query.limit ?? 50);
  const result = await query(
    `select f.*, r.name as repo_name from feed_items f
     join repos r on r.id = f.repo_id
     where f.user_id = $1 order by f.created_at desc limit $2`,
    [req.userId, limit],
  );
  res.json({ items: result.rows });
});
```

## `server/routes/notifications.js` — engine

```javascript
import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';

export const notificationsRouter = Router();

notificationsRouter.post('/notifications/register-device', requireAuth, async (req, res) => {
  const { fcm_token } = req.body;
  if (!fcm_token) return res.status(400).json({ error: 'Missing fcm_token' });
  await query(
    `insert into device_tokens (user_id, fcm_token) values ($1,$2)
     on conflict (fcm_token) do update set user_id = excluded.user_id`,
    [req.userId, fcm_token],
  );
  res.json({ ok: true });
});
```

## `server/routes/internalCron.js` — engine (serverless-friendly cron trigger)

```javascript
import { Router } from 'express';
import { runHourlyScan } from '../lib/hourlyScan.js';

export const internalCronRouter = Router();

/**
 * Use this if you deploy as serverless (no persistent process to host
 * node-cron). Point an external scheduler — Neon Functions' own cron
 * config once you've confirmed the current syntax, a free service like
 * cron-job.org, or a GitHub Actions scheduled workflow doing a `curl`
 * — at this endpoint once an hour. Protected by a shared secret header
 * so randoms can't trigger it.
 */
internalCronRouter.post('/internal/hourly-scan', async (req, res) => {
  if (req.headers['x-cron-secret'] !== process.env.CRON_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const result = await runHourlyScan();
  res.json(result);
});
```

## `server/cron/standalone.js` — engine (persistent-worker cron)

```javascript
import 'dotenv/config';
import cron from 'node-cron';
import { runHourlyScan } from '../lib/hourlyScan.js';

// Use this if the server runs as a long-lived process (Railway, Render,
// Fly, a VPS). Run it as a second process alongside `npm start`:
//   npm run cron
cron.schedule('0 * * * *', runHourlyScan);
console.log('Chomp hourly scan cron started (standalone worker mode).');
```

## `server/index.js` — engine (entry point)

```javascript
import express from 'express';
import 'dotenv/config';
import { authRouter } from './routes/auth.js';
import { reposRouter } from './routes/repos.js';
import { scanRouter } from './routes/scan.js';
import { feedRouter } from './routes/feed.js';
import { notificationsRouter } from './routes/notifications.js';
import { internalCronRouter } from './routes/internalCron.js';

const app = express();
app.use(express.json());

app.use(authRouter);
app.use(reposRouter);
app.use(scanRouter);
app.use(feedRouter);
app.use(notificationsRouter);
app.use(internalCronRouter);

app.get('/health', (req, res) => res.json({ ok: true }));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Chomp server listening on :${port}`));
```

------------------------ WILL RUN THIS MYSELF -----------------------------------------

## Running It

```bash
# Server
cd server
npm install
cp .env.example .env   # fill in real values
psql "$NEON_DATABASE_URL" -f schema.sql
npm start               # API on :3000
npm run cron             # separate terminal/process — the hourly scan worker

# Client
cd ../  # project root
cp .env.example .env    # fill in CHOMP_API_BASE_URL etc.
flutter pub get
dart format .
flutter analyze
flutter run
```

If `flutter analyze` flags anything in `scan_provider.dart` — check the "fix before you run this one" note under that file first, that's the one spot I know needs a manual cleanup pass.

---------------------- DONT DO HERE YET-----------------------------------------
## 7. UI Polish (Last — After Engine Works)

Only start this once every screen can show real data end to end. In order:
1. Empty states (no repos connected yet, watchlist empty, no alerts)
2. Loading skeletons instead of spinners on Home and Repo Detail
3. Light/Dark/System theme toggle wired to `ThemeMode`
4. Accent color picker (store choice in Neon under user settings or locally)
5. Micro-animations on the speedometers and scan log
6. Pull-to-refresh on Home and Feed

---

## 8. CLI Checks Before Running on Your Phone

Run these in order every time before testing on-device — catching issues here is much faster than debugging on a real phone.

```bash
# 1. Get dependencies
flutter pub get

# 2. Format check — auto-fixes formatting issues
dart format .

# 3. Static analysis — type errors, unused imports, lint issues
flutter analyze

# 4. Run any unit tests you've written
flutter test

# 5. Clean build artifacts if you're getting weird stale-build errors
flutter clean
flutter pub get
```

If `flutter analyze` reports issues, fix them before proceeding — don't run on-device with known analyzer errors, they tend to surface as runtime crashes.

### Viewing on your phone

**Android (physical device):**
```bash
# Enable Developer Options + USB Debugging on your phone first
flutter devices          # confirm your phone is listed
flutter run              # builds debug APK and installs directly
```

**iOS (physical device, Mac only):**
```bash
flutter devices
flutter run               # you'll need to trust your developer certificate on the phone the first time, under Settings → General → VPN & Device Management
```

**Hot reload while developing:** once `flutter run` is active, press `r` in the terminal for hot reload, `R` for hot restart.

---

## 9. Producing an APK (Android) for GitHub Release + Phone Install

```bash
# Debug APK — fastest, larger file, includes debug info
flutter build apk --debug

# Release APK — what you actually want to share/distribute
flutter build apk --release

# Split per-architecture (smaller individual files, recommended for distribution)
flutter build apk --release --split-per-abi
```

Output location:
```
build/app/outputs/flutter-apk/app-release.apk
```
(or `app-arm64-v8a-release.apk` etc. if you used `--split-per-abi`)

### Installing directly on your phone
```bash
flutter install     # installs the most recent build directly if phone is connected
# or manually copy the .apk to your phone and open it (enable "install from unknown sources" first)
```

### Publishing the APK to GitHub
1. Commit your code as normal (the `.env` file should already be gitignored — double check it never got committed)
2. On GitHub, go to your repo → **Releases** → **Draft a new release**
3. Tag it (e.g. `v0.1.0`), write release notes
4. Drag the `.apk` file from `build/app/outputs/flutter-apk/` into the release assets
5. Publish — anyone with the link can now download and sideload it

### Before your first release — sign the release build properly
A debug-signed release APK will show warnings and can't later be upgraded to a Play Store build with a different signature. Generate a proper keystore:
```bash
keytool -genkey -v -keystore ~/chomp-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chomp
```
Then configure `android/key.properties` and reference it in `android/app/build.gradle` per Flutter's official Android deployment docs (this step is worth doing once, early, rather than retrofitting it after you've already shared APKs signed with the debug key).

---

## 10. Quick Reference — Full Command Sequence

```bash
# One-time setup
flutter create chomp --org com.yourname --platforms=android,ios
cd chomp
flutter pub get

# Every session before testing
dart format .
flutter analyze
flutter test
flutter run

# When ready to share
flutter build apk --release --split-per-abi
# → upload build/app/outputs/flutter-apk/*.apk to GitHub Releases
```
